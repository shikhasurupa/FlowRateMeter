from tkinter import *
from tkinter import ttk
import threading as thr
from main.data_logger import *
import main.global_vars as global_vars

#pip install pyserial requests if you dont have it  
import time		 #Thingspeak
import requests  #Thingspeak


#create_widgets(): Populates TKInter GUI
def create_widgets(flowrate, total_vol, avg_flowrate):
  ttk.Label(frame, text = "Water Flow Sensor").grid(column=1, row=0, padx=10, pady=10)
  ttk.Label(frame, textvariable = flowrate).grid(column=0, row=1, padx=10, pady=10)
  ttk.Label(frame, textvariable = total_vol).grid(column=1, row=1, padx=10, pady=10)
  ttk.Label(frame, textvariable = avg_flowrate).grid(column=2, row=1, padx=10, pady=10)
  ttk.Button(frame, text="Refresh", command=lambda: refresh_data(g_lock)).grid(column=0, row=2)
  ttk.Button(frame, text="Quit", command=lambda: shutdown_app(root, t)).grid(column=2, row=2)

  flowrate.set("Flow Rate: N/A")
  total_vol.set("Total Volume: N/A")
  avg_flowrate.set("Average Flow Rate: N/A")

#refresh_data(): once lock is aquired, reads global vars to update text
def refresh_data(g_lock):
  with g_lock:
    flowrate.set(f"Flow Rate: {global_vars.g_flowrate}")
    total_vol.set(f"Total Volume: {global_vars.g_total_vol}")
    avg_flowrate.set(f"Average Flow Rate: {global_vars.g_avg_flowrate}")

#shutdown_app(): Handles shutdown of serial and database connection
def shutdown_app(root, t):
  t.running = False
  t.join()
  root.after(0, root.destroy)

#initialize global variables from module
global_vars.init()
g_lock = thr.Lock()

#initialize TKInter Window
root = Tk()
root.title('Project FlowMeter')
frame = ttk.Frame(root, padding=15)
frame.grid()

flowrate = StringVar()
total_vol = StringVar()
avg_flowrate = StringVar()
create_widgets(flowrate, total_vol, avg_flowrate)

#Establish database connection

# Need to make an HTTP request since we are sending from Python
# Student licenses allow a piece of data per second, might want to limit with an average per second from flowMeter.ino
#comm = serial.serial('COM5', 115200) # Confirm com port for laptop being used since we cant send from arduino
									 # Maybe suggest attached ESP32 or device change next semester for direct comms
#thingspeakKey = 0E4NVRSW981M90O9	 # General API key, can be regenerated on site 

#while True:							 #
#	try:
#		if com.in_waiting:		     #Checking Serial for data

#		flowrate = ser.readline().decode('utf-8').strip()
#        print(f"Flow Rate: {flowrate}")
		
#		url = 'https://api.thingspeak.com/update.json'
#		params = {
#			'api_key': thingspeakKey,
#			'field1': flowrate
#		}
		
#		response = requests.post(url, data=params) # System response for debugging 
#		print(response.text)


#Establish Thread for reading serial data
t = thr.Thread(target=logger_loop, args=(g_lock,))
t.start()

#Begin Displaying TKInter Window
root.mainloop()
