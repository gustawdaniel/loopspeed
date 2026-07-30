#!/usr/bin/env python3
# /// script
# dependencies = [
#   "numpy",
#   "scipy",
#   "matplotlib",
# ]
# ///

import os
import sqlite3
import numpy as np
import matplotlib.pyplot as plt
from scipy.optimize import curve_fit

def model_func(x_log, a, B):
    return np.log(np.exp(a) * np.exp(x_log) + np.maximum(B, 1e-12))

def main():
    db_path = os.path.join(os.getcwd(), "log/log.db")
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("Connecting to database...")

    cursor.execute("SELECT name FROM log GROUP BY name ORDER BY name")
    languages = [row[0] for row in cursor.fetchall()]

    params = []

    for lang in languages:
        cursor.execute("SELECT size, time FROM log WHERE name=?", (lang,))
        rows = cursor.fetchall()
        sizes = np.array([r[0] for r in rows], dtype=float)
        times = np.array([r[1] for r in rows], dtype=float)

        min_time = max(np.min(times), 1e-6)
        max_size = np.max(sizes)
        a_guess = np.log(max(min_time / max_size, 1e-15))
        B_guess = min_time

        p0 = [a_guess, B_guess]
        bounds = ([-40.0, 1e-12], [10.0, 100.0])
        try:
            popt, _ = curve_fit(model_func, np.log(sizes), np.log(times), p0=p0, bounds=bounds, maxfev=20000)
            a, B = popt
        except Exception:
            a, B = a_guess, B_guess

        A = np.exp(a)
        params.append((lang, a, A, B, np.log(max(B, 1e-12))))

        # Individual plot for each language
        fig, ax = plt.subplots(figsize=(10, 6))
        ax.scatter(sizes, times, color='red', alpha=0.7, label='Experimental data', zorder=5)

        x_fit = np.logspace(0, 13, 500)
        y_fit = A * x_fit + B

        ax.plot(x_fit, y_fit, color='blue', linewidth=2, label=f'Model: T = {A:.2e} * N + {B:.4f}', zorder=4)

        ax.set_xscale('log')
        ax.set_yscale('log')
        ax.set_xlabel('$size [number of loops]', fontsize=12)
        ax.set_ylabel('$time [sec]', fontsize=12)
        ax.set_title(f'Performance Analysis: {lang}', fontsize=14)
        ax.grid(True, which="both", linestyle="--", alpha=0.5)
        ax.legend(loc='upper left', fontsize=11)

        out_path = f"inc_{lang}.png"
        plt.tight_layout()
        plt.savefig(out_path, dpi=150)
        plt.close(fig)
        print(f"Generated plot: {out_path}")

    # Summary plot 1: Compare of loop time (speed.png)
    sorted_by_A = sorted(params, key=lambda x: x[2])
    langs_A = [item[0] for item in sorted_by_A]
    log_a_vals = [item[1] for item in sorted_by_A]

    fig, ax = plt.subplots(figsize=(12, 6))
    colors = plt.cm.plasma(np.linspace(0, 1, len(langs_A)))
    bars = ax.bar(langs_A, log_a_vals, color=colors)
    ax.set_ylabel('Log[a] (Log of time per loop)', fontsize=12)
    ax.set_title('Comparison of Single Loop Execution Time (Lower is better)', fontsize=14)
    plt.xticks(rotation=45, ha='right', fontsize=10)
    ax.grid(True, axis='y', linestyle='--', alpha=0.5)
    plt.tight_layout()
    plt.savefig("speed.png", dpi=150)
    plt.close(fig)
    print("Generated plot: speed.png")

    # Summary plot 2: Compare of startup time (speed2.png)
    sorted_by_B = sorted(params, key=lambda x: x[3])
    langs_B = [item[0] for item in sorted_by_B]
    log_b_vals = [item[4] for item in sorted_by_B]

    fig, ax = plt.subplots(figsize=(12, 6))
    colors = plt.cm.viridis(np.linspace(0, 1, len(langs_B)))
    bars = ax.bar(langs_B, log_b_vals, color=colors)
    ax.set_ylabel('Log[b] (Log of startup overhead time)', fontsize=12)
    ax.set_title('Comparison of Program Startup Time (Lower is better)', fontsize=14)
    plt.xticks(rotation=45, ha='right', fontsize=10)
    ax.grid(True, axis='y', linestyle='--', alpha=0.5)
    plt.tight_layout()
    plt.savefig("speed2.png", dpi=150)
    plt.close(fig)
    print("Generated plot: speed2.png")

    print("All plots generated successfully.")

if __name__ == "__main__":
    main()
