import threading as thr
import time
import sqlite3
import global_vars
import RPi.GPIO as GPIO

FLOW_PIN = 17
CALIBRATION_FACTOR = 1

pulse_count = 0
start_time = time.time()
total_ml = 0

DB_FILE = "flow_data.db"

def flow_pulse(channel):
    global pulse_count
    pulse_count += 1


def update_globals(g_lock, flowrate, total_vol, avg_flowrate):
    with g_lock:
        global_vars.g_flowrate = flowrate
        global_vars.g_total_vol = total_vol
        global_vars.g_avg_flowrate = avg_flowrate


def init_db():
    conn = sqlite3.connect(DB_FILE)
    cur = conn.cursor()
    cur.execute("""
        CREATE TABLE IF NOT EXISTS flow_data (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp REAL,
            flowrate REAL,
            total_volume REAL,
            avg_flowrate REAL
        )
    """)
    conn.commit()
    conn.close()


def insert_db(timestamp, flowrate, total_vol, avg_flowrate):
    conn = sqlite3.connect(DB_FILE)
    cur = conn.cursor()
    cur.execute(
        "INSERT INTO flow_data (timestamp, flowrate, total_volume, avg_flowrate) VALUES (?, ?, ?, ?)",
        (timestamp, flowrate, total_vol, avg_flowrate)
    )
    conn.commit()
    conn.close()


def logger_loop(g_lock):
    global pulse_count, total_ml

    t = thr.currentThread()

    init_db()

    # GPIO init
    GPIO.setmode(GPIO.BCM)
    GPIO.setup(FLOW_PIN, GPIO.IN, pull_up_down=GPIO.PUD_UP)
    GPIO.add_event_detect(FLOW_PIN, GPIO.FALLING, callback=flow_pulse)

    last_time = time.time()

    while getattr(t, "running", True):
        time.sleep(1)

        current_time = time.time()
        elapsed = current_time - last_time

        flowrate = (pulse_count / elapsed) / CALIBRATION_FACTOR
        flow_ml = (flowrate / 60) * 1000
        total_ml += flow_ml

        avg_flowrate = total_ml / (current_time - start_time)

        pulse_count = 0
        last_time = current_time

        update_globals(g_lock, flowrate, total_ml, avg_flowrate)
        insert_db(current_time, flowrate, total_ml, avg_flowrate)

    GPIO.cleanup()