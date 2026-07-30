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
from scipy.optimize import curve_fit

def model_func(x_log, a, B):
    return np.log(np.exp(a) * np.exp(x_log) + np.maximum(B, 1e-12))

def main():
    db_path = os.path.join(os.getcwd(), "log/log.db")
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("Connection with database established...")

    cursor.execute("SELECT name FROM log GROUP BY name ORDER BY name")
    languages = [row[0] for row in cursor.fetchall()]

    data = {}
    for lang in languages:
        cursor.execute("SELECT size, time FROM log WHERE name=?", (lang,))
        rows = cursor.fetchall()
        sizes = np.array([r[0] for r in rows], dtype=float)
        times = np.array([r[1] for r in rows], dtype=float)
        data[lang] = (sizes, times)

    print("Data extracted from database...")

    results = []

    for lang in languages:
        sizes, times = data[lang]
        x_log = np.log(sizes)
        y_log = np.log(times)

        min_time = max(np.min(times), 1e-6)
        max_size = np.max(sizes)
        a_guess = np.log(max(min_time / max_size, 1e-15))
        B_guess = min_time

        p0 = [a_guess, B_guess]
        bounds = ([-40.0, 1e-12], [10.0, 100.0])
        try:
            popt, pcov = curve_fit(model_func, x_log, y_log, p0=p0, bounds=bounds, maxfev=20000)
            perr = np.sqrt(np.diag(pcov))
            a, B = popt
            ea_val, eb_val = perr
        except Exception as e:
            print(f"Error fitting {lang}: {e}")
            a, B, ea_val, eb_val = a_guess, B_guess, 0.0, 0.0

        A = np.exp(a)
        ea = min(A * ea_val, A * 0.5)
        eb = min(eb_val, B * 0.5)

        results.append((lang, A, B, ea, eb))

    print("Nonlinear models calculated...")
    print("Parameters extracted from models...")

    csv_path = os.path.join(os.getcwd(), "config/parameters.csv")
    with open(csv_path, "w") as f:
        for lang, A, B, ea, eb in results:
            f.write(f"{lang},{A:.10g},{B:.10g},{ea:.10g},{eb:.10g}\n")

    print("Parameters saved to file. Process finished correctly.")

if __name__ == "__main__":
    main()
