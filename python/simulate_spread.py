"""Simulate exposure spread from positive residents using priority queue + 4-direction adjacency."""

from __future__ import annotations

import argparse
import csv
import heapq
import math
import os
import sqlite3
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, Iterable, List, Tuple


@dataclass(frozen=True)
class SeatNode:
    resident_id: int
    auditorium_number: int
    row_number: int
    seat_number: int


def fetch_rows(conn: Any, query: str, engine: str) -> List[Dict[str, Any]]:
    if engine == "sqlite":
        conn.row_factory = sqlite3.Row
        cur = conn.cursor()
        cur.execute(query)
        return [dict(r) for r in cur.fetchall()]

    cur = conn.cursor(dictionary=True)
    cur.execute(query)
    return cur.fetchall()


def get_connection(engine: str, db_path: str) -> Any:
    if engine == "sqlite":
        return sqlite3.connect(db_path)

    try:
        import mysql.connector  # type: ignore
    except ImportError as exc:
        raise RuntimeError(
            "MySQL engine selected but mysql-connector-python is not installed."
        ) from exc

    return mysql.connector.connect(
        host=os.getenv("MYSQL_HOST", "127.0.0.1"),
        port=int(os.getenv("MYSQL_PORT", "3306")),
        user=os.getenv("MYSQL_USER", "root"),
        password=os.getenv("MYSQL_PASSWORD", ""),
        database=os.getenv("MYSQL_DATABASE", "zovid"),
    )


def build_adjacency(nodes: List[SeatNode]) -> Dict[int, List[int]]:
    by_auditorium: Dict[int, Dict[Tuple[int, int], int]] = {}
    for node in nodes:
        by_auditorium.setdefault(node.auditorium_number, {})[(node.row_number, node.seat_number)] = node.resident_id

    graph: Dict[int, List[int]] = {}
    offsets = [(-1, 0), (1, 0), (0, -1), (0, 1)]

    for seat_map in by_auditorium.values():
        for (row, seat), resident_id in seat_map.items():
            graph.setdefault(resident_id, [])
            for dr, ds in offsets:
                neighbor = seat_map.get((row + dr, seat + ds))
                if neighbor is not None and neighbor != resident_id:
                    graph[resident_id].append(neighbor)

    return graph


def dijkstra_spread(graph: Dict[int, List[int]], seeds: Iterable[int], risk_scores: Dict[int, float]) -> Dict[int, float]:
    inf = float('inf')
    dist: Dict[int, float] = {node: inf for node in graph}
    pq: List[Tuple[float, int]] = []

    for seed in seeds:
        if seed in dist:
            dist[seed] = 0.0
            heapq.heappush(pq, (0.0, seed))

    while pq:
        cur_t, u = heapq.heappop(pq)
        if cur_t > dist[u]:
            continue

        for v in graph.get(u, []):
            step = 1.0 + math.log1p(max(risk_scores.get(v, 1.0), 1.0)) / 3.0
            new_t = cur_t + step
            if new_t < dist.get(v, inf):
                dist[v] = new_t
                heapq.heappush(pq, (new_t, v))

    return dist


def main() -> None:
    parser = argparse.ArgumentParser(description='Compute exposure_time using seat adjacency spread model.')
    parser.add_argument('--engine', choices=['sqlite', 'mysql'], default='sqlite', help='Database engine')
    parser.add_argument('--db', default='project.db', help='SQLite database path')
    parser.add_argument('--out', default='outputs/exposure_time.csv', help='Output CSV path')
    args = parser.parse_args()

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)

    conn = get_connection(args.engine, args.db)

    seat_rows = fetch_rows(
        conn,
        """
        SELECT DISTINCT resident_id, auditorium_number, row_number, seat_number
        FROM audiences
        WHERE resident_id IS NOT NULL
        """,
        args.engine,
    )
    feature_rows = fetch_rows(
        conn,
        """
        SELECT resident_id, risk_score, is_positive
        FROM resident_features
        """,
        args.engine,
    )

    nodes = [
        SeatNode(
            resident_id=int(r["resident_id"]),
            auditorium_number=int(r["auditorium_number"]),
            row_number=int(r["row_number"]),
            seat_number=int(r["seat_number"]),
        )
        for r in seat_rows
    ]

    graph = build_adjacency(nodes)
    risk_scores = {int(r["resident_id"]): float(r["risk_score"]) for r in feature_rows}
    seeds = [int(r["resident_id"]) for r in feature_rows if int(r["is_positive"] or 0) == 1]
    dist = dijkstra_spread(graph, seeds, risk_scores)

    with out_path.open('w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(['resident_id', 'exposure_time'])
        for resident_id, exposure_time in sorted(dist.items(), key=lambda x: x[1]):
            if math.isinf(exposure_time):
                continue
            writer.writerow([resident_id, round(exposure_time, 4)])

    conn.close()


if __name__ == '__main__':
    main()
