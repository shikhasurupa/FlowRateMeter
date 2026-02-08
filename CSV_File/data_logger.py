import threading as thr
import time
import csv
import global_vars
import RPi.GPIO as GPIO

FLOW_PIN = 17        
CALIBRATION_FACTOR = 1

pulse_count = 0
start_time = time.time()
total_ml = 0

CSV_FILE = "flow_data.csv"

# Interrupt callback
def flow_pulse(channel):
    global pulse_count
    pulse_count += 1


def update_globals(g_lock, flowrate, total_vol, avg_flowrate):
    with g_lock:
        global_vars.g_flowrate = flowrate
        global_vars.g_total_vol = total_vol
        global_vars.g_avg_flowrate = avg_flowrate


def write_csv(flowrate, total_vol, avg_flowrate):
    with open(CSV_FILE, 'a', newline='') as f:
        writer = csv.writer(f)
        writer.writerow([time.time(), flowrate, total_vol, avg_flowrate])


def logger_loop(g_lock):
    global pulse_count, total_ml

    t = thr.currentThread()

    # GPIO init
    GPIO.setmode(GPIO.BCM)
    GPIO.setup(FLOW_PIN, GPIO.IN, pull_up_down=GPIO.PUD_UP)
    GPIO.add_event_detect(FLOW_PIN, GPIO.FALLING, callback=flow_pulse)

    with open(CSV_FILE, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(["timestamp", "flowrate", "total_volume_ml", "avg_flowrate"])

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
        write_csv(flowrate, total_ml, avg_flowrate)

    GPIO.cleanup()