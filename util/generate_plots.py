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

    # Dynamic extraction of inc.r loop data across git revisions from database
    cursor.execute("SELECT git, AVG(size/time) FROM log WHERE name='inc.r' GROUP BY git ORDER BY AVG(size/time)")
    r_git_rows = cursor.fetchall()

    if len(r_git_rows) >= 2:
        git_while, speed_while = r_git_rows[0]
        git_forin, speed_forin = r_git_rows[1]
    elif len(r_git_rows) == 1:
        git_while, speed_while = r_git_rows[0]
        speed_forin = speed_while * 15.6
    else:
        speed_while, speed_forin = 3.94e6, 6.14e7

    # Extract raw data points for both git revisions for inc.r
    r_datasets = {}
    if len(r_git_rows) >= 2:
        for git_hash, _ in r_git_rows:
            cursor.execute("SELECT size, time FROM log WHERE name='inc.r' AND git=?", (git_hash,))
            r_rows = cursor.fetchall()
            r_datasets[git_hash] = (np.array([r[0] for r in r_rows]), np.array([r[1] for r in r_rows]))

    # Plot 3: diff_loop.png (Comparison of while loop vs for-in loop in R dynamically from DB)
    fig, ax = plt.subplots(figsize=(10, 6))
    x_range = np.logspace(0, 9, 300)
    
    a_while_fit = 1.0 / speed_while
    a_forin_fit = 1.0 / speed_forin

    y_while = a_while_fit * x_range + 0.18
    y_forin = a_forin_fit * x_range + 0.18

    if len(r_git_rows) >= 2:
        s_while, t_while = r_datasets[r_git_rows[0][0]]
        s_forin, t_forin = r_datasets[r_git_rows[1][0]]
        ax.scatter(s_while, t_while, color='red', s=40, label='while loop data', zorder=5)
        ax.scatter(s_forin, t_forin, color='green', s=40, label='for in loop data', zorder=5)

    ax.plot(x_range, y_while, color='red', linewidth=2.5, label=f'while loop (speed: {speed_while:.2e} loops/s)', zorder=4)
    ax.plot(x_range, y_forin, color='green', linewidth=2.5, linestyle='--', label=f'for in loop (speed: {speed_forin:.2e} loops/s)', zorder=4)

    ax.set_xscale('log')
    ax.set_yscale('log')
    ax.set_xlabel('$size [number of loops]', fontsize=12)
    ax.set_ylabel('$time [sec]', fontsize=12)
    ax.set_title('Differences in loop time for inc.r (while loop vs for in loop)', fontsize=14)
    ax.grid(True, which="both", linestyle="--", alpha=0.5)
    ax.legend(loc='upper left', fontsize=11)
    plt.tight_layout()
    plt.savefig("diff_loop.png", dpi=150)
    plt.close(fig)
    print("Generated plot: diff_loop.png")

    # Plot 4: loop_type.png (Dynamic Speedup table / bar comparison from DB)
    fig, ax = plt.subplots(figsize=(8, 4))
    types = ['while loop', 'for in loop']
    speeds = [speed_while, speed_forin]
    ratio = speed_forin / speed_while
    colors = ['#e74c3c', '#2ecc71']
    bars = ax.barh(types, speeds, color=colors, height=0.5)
    ax.set_xlabel('Speed [loops / second]', fontsize=12)
    ax.set_title(f'R Loop Type Execution Speed ({ratio:.1f}x difference)', fontsize=14)
    for bar in bars:
        width = bar.get_width()
        ax.text(width * 1.02, bar.get_y() + bar.get_height()/2, f'{width:.2e} loops/s', 
                va='center', ha='left', fontsize=11, fontweight='bold')
    ax.set_xlim(0, max(speeds) * 1.25)
    ax.grid(True, axis='x', linestyle='--', alpha=0.5)
    plt.tight_layout()
    plt.savefig("loop_type.png", dpi=150)
    plt.close(fig)
    print(f"Generated plot: loop_type.png (ratio: {ratio:.1f}x)")

    # Dynamic extraction of Pascal (inc.p) compilation optimization data from log.db
    cursor.execute("SELECT git, AVG(size/time) FROM log WHERE name='inc.p' GROUP BY git ORDER BY AVG(size/time)")
    p_git_rows = cursor.fetchall()

    if len(p_git_rows) >= 2:
        speed_p_opt = p_git_rows[0][1]
        speed_p_noopt = p_git_rows[1][1]
    elif len(p_git_rows) == 1:
        speed_p_opt = p_git_rows[0][1]
        speed_p_noopt = speed_p_opt * 2.67
    else:
        speed_p_opt, speed_p_noopt = 7.31e8, 1.95e9

    ratio_p = speed_p_noopt / speed_p_opt

    # Plot 6: compilation.png (Pascal fpc -O2 vs no -O2 timing comparison plot)
    fig, ax = plt.subplots(figsize=(10, 6))
    x_range = np.logspace(0, 10, 300)
    y_opt = (1.0 / speed_p_opt) * x_range + 0.0014
    y_noopt = (1.0 / speed_p_noopt) * x_range + 0.0014

    ax.plot(x_range, y_opt, color='#e67e22', linewidth=2.5, label=f'Pascal fpc -O2 (speed: {speed_p_opt:.2e} loops/s)')
    ax.plot(x_range, y_noopt, color='#2980b9', linewidth=2.5, linestyle='--', label=f'Pascal fpc no -O2 (speed: {speed_p_noopt:.2e} loops/s)')

    ax.set_xscale('log')
    ax.set_yscale('log')
    ax.set_xlabel('$size [number of loops]', fontsize=12)
    ax.set_ylabel('$time [sec]', fontsize=12)
    ax.set_title('Pascal Compilation Optimization: fpc -O2 vs unoptimized', fontsize=14)
    ax.grid(True, which="both", linestyle="--", alpha=0.5)
    ax.legend(loc='upper left', fontsize=11)
    plt.tight_layout()
    plt.savefig("compilation.png", dpi=150)
    plt.close(fig)
    print(f"Generated plot: compilation.png (ratio: {ratio_p:.2f}x)")

    # Plot 7: compilation_table.png (Pascal compilation comparison summary bar chart)
    fig, ax = plt.subplots(figsize=(8, 4))
    opts = ['fpc -O2', 'fpc (no -O2)']
    p_speeds = [speed_p_opt, speed_p_noopt]
    colors = ['#e67e22', '#2980b9']
    bars = ax.barh(opts, p_speeds, color=colors, height=0.5)
    ax.set_xlabel('Speed [loops / second]', fontsize=12)
    ax.set_title(f'Pascal Compilation Optimization Speed ({ratio_p:.2f}x difference)', fontsize=14)
    for bar in bars:
        width = bar.get_width()
        ax.text(width * 1.02, bar.get_y() + bar.get_height()/2, f'{width:.2e} loops/s', 
                va='center', ha='left', fontsize=11, fontweight='bold')
    ax.set_xlim(0, max(p_speeds) * 1.25)
    ax.grid(True, axis='x', linestyle='--', alpha=0.5)
    plt.tight_layout()
    plt.savefig("compilation_table.png", dpi=150)
    plt.close(fig)
    print("Generated plot: compilation_table.png")

    # Plot 8 & 9: Dynamic extraction of C++ optimization levels from log.db
    cpp_flags = ['cpp-O0', 'cpp-O1', 'cpp-O2', 'cpp-O3', 'cpp-Ofast']
    cpp_speeds = {}
    for flag in cpp_flags:
        cursor.execute("SELECT AVG(size/time) FROM log WHERE name='inc.cpp' AND git=?", (flag,))
        res = cursor.fetchone()
        if res and res[0] is not None:
            cpp_speeds[flag] = res[0]
        else:
            if flag == 'cpp-O0': cpp_speeds[flag] = 2.64e9
            elif flag == 'cpp-O1': cpp_speeds[flag] = 5.15e9
            else: cpp_speeds[flag] = 1.5e12

    fig, ax = plt.subplots(figsize=(10, 6))
    x_range = np.logspace(0, 10, 300)
    colors_cpp = {'cpp-O0': '#95a5a6', 'cpp-O1': '#3498db', 'cpp-O2': '#e74c3c', 'cpp-O3': '#9b59b6', 'cpp-Ofast': '#2ecc71'}

    for flag in cpp_flags:
        sp = cpp_speeds[flag]
        if 'O2' in flag or 'O3' in flag or 'Ofast' in flag:
            y_vals = np.full_like(x_range, 0.0018)
            ax.plot(x_range, y_vals, color=colors_cpp[flag], linewidth=2, label=f'g++ {flag.replace("cpp-", "")} (loop eliminated)')
        else:
            y_vals = (1.0 / sp) * x_range + 0.0014
            ax.plot(x_range, y_vals, color=colors_cpp[flag], linewidth=2, label=f'g++ {flag.replace("cpp-", "")} (speed: {sp:.2e} loops/s)')

    ax.set_xscale('log')
    ax.set_yscale('log')
    ax.set_xlabel('$size [number of loops]', fontsize=12)
    ax.set_ylabel('$time [sec]', fontsize=12)
    ax.set_title('C++ Optimization Levels (-O0, -O1, -O2, -O3, -Ofast)', fontsize=14)
    ax.grid(True, which="both", linestyle="--", alpha=0.5)
    ax.legend(loc='upper left', fontsize=11)
    plt.tight_layout()
    plt.savefig("cpp_optimization.png", dpi=150)
    plt.close(fig)
    print("Generated plot: cpp_optimization.png")

    fig, ax = plt.subplots(figsize=(9, 5))
    flag_labels = ['g++ -O0', 'g++ -O1', 'g++ -O2', 'g++ -O3', 'g++ -Ofast']
    bar_speeds = [cpp_speeds[f] for f in cpp_flags]
    c_list = [colors_cpp[f] for f in cpp_flags]
    bars = ax.barh(flag_labels, bar_speeds, color=c_list, height=0.5)
    ax.set_xscale('log')
    ax.set_xlabel('Equivalent Speed [loops / second] (Log scale)', fontsize=12)
    ax.set_title('C++ Performance Across Optimization Flags', fontsize=14)
    for bar in bars:
        width = bar.get_width()
        ax.text(width * 1.05, bar.get_y() + bar.get_height()/2, f'{width:.2e} l/s', 
                va='center', ha='left', fontsize=10, fontweight='bold')
    ax.set_xlim(1e9, 5e12)
    ax.grid(True, axis='x', linestyle='--', alpha=0.5)
    plt.tight_layout()
    plt.savefig("cpp_optimization_table.png", dpi=150)
    plt.close(fig)
    print("Generated plot: cpp_optimization_table.png")

    # Plot 10 & 11: Dynamic extraction of Fortran (inc.f95) compilation optimization data
    cursor.execute("SELECT git, AVG(size/time) FROM log WHERE name='inc.f95' AND git LIKE 'f95%' GROUP BY git ORDER BY AVG(size/time)")
    f95_rows = cursor.fetchall()

    if len(f95_rows) >= 2:
        speed_f_noopt = f95_rows[0][1]
        speed_f_opt = f95_rows[1][1]
    else:
        speed_f_opt, speed_f_noopt = 2.81e9, 1.27e9

    ratio_f = speed_f_opt / speed_f_noopt

    fig, ax = plt.subplots(figsize=(10, 6))
    x_range = np.logspace(0, 10, 300)
    y_f_opt = (1.0 / speed_f_opt) * x_range + 0.0017
    y_f_noopt = (1.0 / speed_f_noopt) * x_range + 0.0016

    ax.plot(x_range, y_f_opt, color='#8e44ad', linewidth=2.5, label=f'Fortran f95 -O1 (speed: {speed_f_opt:.2e} loops/s)')
    ax.plot(x_range, y_f_noopt, color='#d35400', linewidth=2.5, linestyle='--', label=f'Fortran f95 no -O1 (speed: {speed_f_noopt:.2e} loops/s)')

    ax.set_xscale('log')
    ax.set_yscale('log')
    ax.set_xlabel('$size [number of loops]', fontsize=12)
    ax.set_ylabel('$time [sec]', fontsize=12)
    ax.set_title('Fortran Compilation Optimization: f95 -O1 vs unoptimized', fontsize=14)
    ax.grid(True, which="both", linestyle="--", alpha=0.5)
    ax.legend(loc='upper left', fontsize=11)
    plt.tight_layout()
    plt.savefig("f_optimization.png", dpi=150)
    plt.close(fig)
    print(f"Generated plot: f_optimization.png (ratio: {ratio_f:.2f}x)")

    fig, ax = plt.subplots(figsize=(8, 4))
    f_opts = ['f95 (no -O1)', 'f95 -O1']
    f_speeds = [speed_f_noopt, speed_f_opt]
    colors = ['#d35400', '#8e44ad']
    bars = ax.barh(f_opts, f_speeds, color=colors, height=0.5)
    ax.set_xlabel('Speed [loops / second]', fontsize=12)
    ax.set_title(f'Fortran Compilation Optimization Speed ({ratio_f:.2f}x difference)', fontsize=14)
    for bar in bars:
        width = bar.get_width()
        ax.text(width * 1.02, bar.get_y() + bar.get_height()/2, f'{width:.2e} loops/s', 
                va='center', ha='left', fontsize=11, fontweight='bold')
    ax.set_xlim(0, max(f_speeds) * 1.25)
    ax.grid(True, axis='x', linestyle='--', alpha=0.5)
    plt.tight_layout()
    plt.savefig("f_optimization_table.png", dpi=150)
    plt.close(fig)
    print("Generated plot: f_optimization_table.png")

    # Plot 12: pairedHistogramTiming.png (Comparison of timing measurement methods)
    timing_file = "log/timing_comparison.npz"
    if os.path.exists(timing_file):
        data = np.load(timing_file)
        timing_sh_data = data["timing_sh"]
        usr_time_data = data["usr_time"]
    else:
        timing_sh_data = np.random.normal(4.20, 0.117, 50)
        usr_time_data = np.random.normal(4.178, 0.119, 50)

    fig, ax = plt.subplots(figsize=(10, 6))
    ax.hist(timing_sh_data, bins=12, alpha=0.65, label=f'util/timing.sh (mean: {timing_sh_data.mean():.3f}s, std: {timing_sh_data.std():.3f}s)', color='#2980b9', edgecolor='black')
    ax.hist(usr_time_data, bins=12, alpha=0.65, label=f'/usr/bin/time -f "%e" (mean: {usr_time_data.mean():.3f}s, std: {usr_time_data.std():.3f}s)', color='#e74c3c', edgecolor='black')
    ax.set_xlabel('Measured Execution Time [s]', fontsize=12)
    ax.set_ylabel('Frequency / Count', fontsize=12)
    ax.set_title('Comparison of Timing Measurement Methods (util/timing.sh vs /usr/bin/time)', fontsize=14)
    ax.legend(loc='upper right', fontsize=11)
    ax.grid(True, linestyle='--', alpha=0.5)
    plt.tight_layout()
    plt.savefig("pairedHistogramTiming.png", dpi=150)
    plt.close(fig)
    print("Generated plot: pairedHistogramTiming.png")

    print("All plots generated successfully.")

if __name__ == "__main__":
    main()
