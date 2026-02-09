import serial
import threading as thr
import time
import main.global_vars as global_vars

#pip install pyserial requests if you dont have it  
import time		 #Thingspeak
import requests  #Thingspeak

thingspeakKey = '0E4NVRSW981M90O9'

#read_data(): retrieves data from Ardiuno, updating variables
def read_data(arduino):
  new_data = {'flowrate': 0.0, 'total_vol': 0.0, 'avg_flowrate': 0.0, 'null_input': False}
  
  #read data in bytes
  flowRate = str(arduino.readline().decode("utf-8")).rstrip()
  if (flowRate == None or ''):
    new_data['null_input'] = True
  else:
    total_vol = str(arduino.readline().decode("utf-8")).rstrip()
    time = str(arduino.readline().decode("utf-8")).rstrip()
    total_flow = str(arduino.readline().decode("utf-8")).rstrip()
    #update dict with new values
    print(flowRate)
    new_data['flowrate'] = float(flowRate)
    new_data['total_vol'] = float(total_vol)
    new_data['avg_flowrate'] = float(total_flow)/float(time)
  
  return new_data

#update_globals(): once lock is aquired, allows other thread to receive new data
def update_globals(g_lock, flowrate, total_vol, avg_flowrate):
  with g_lock:
    global_vars.g_flowrate = flowrate
    global_vars.g_total_vol = total_vol
    global_vars.g_avg_flowrate = avg_flowrate

#update_database(): connects to Thingspeak to update it with new data
def update_database(flowrate, total_vol, avg_flowrate):
  #flowrate = serial.readline().decode('utf-8').strip()
  url = 'https://api.thingspeak.com/update.json'
  params = {
    'api_key': thingspeakKey,
	'field1': flowrate
  }
  response = requests.post(url, data=params) # System response for debugging 
  print(response.text)
  print(f"{flowrate} {total_vol} {avg_flowrate}")

#Main Thread loop
def logger_loop(g_lock):
  #open serial port
  t = thr.currentThread()
  
  #connect to the arduino on COM5
  arduino = serial.Serial(port='COM5', baudrate=115200, timeout=.1)

  while(getattr(t, "running", True)):
    new_data = read_data(arduino)
    if(new_data['null_input'] == False):
      update_globals(g_lock, new_data['flowrate'], new_data['total_vol'], new_data['avg_flowrate'])
      update_database(new_data['flowrate'], new_data['total_vol'], new_data['avg_flowrate'])
    time.sleep(1) #change sleep seconds as needed

  #close serial port
  arduino.close()
