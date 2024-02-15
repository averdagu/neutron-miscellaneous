import subprocess
import json
import time
import sys

def getJson():
    result = subprocess.run(["oc", "get", "ovndbclusters", "ovndbcluster-sb", "-o", "json"], stdout=subprocess.PIPE)
    return json.loads(result.stdout.decode('utf-8'))

def getTypeStatus(conditions, statusType):
    for c in conditions:
        if c['type'] == statusType:
            return c
    return None

def printOutput(historic):
    print("Printing output")
    last_time = None
    for h in historic:
        if last_time:
            time_difference = h['time'] - last_time
        else:
            time_difference = 0
        last_time = h['time']
        print("Type: {}, status: {}, time: {} difference {}".format(h['type'], h['status'], h['time'], time_difference))

def main():
    #output = {'time': None, 'status': None, 'type': None}
    historic = []
    print("Hello")
    try:
        while True:
            output = getJson()
            cond = getTypeStatus(output['status']['conditions'], "ExposeServiceReady")
            if len(historic) == 0 or historic[-1]['status'] != cond['status']:
                print("Appending status {}".format(cond['status']))
                historic.append({'time': time.time(), 'status': cond['status'], 'type': "ExposeServiceReady"})
            time.sleep(0.05)
    except KeyboardInterrupt:
        printOutput(historic)
        sys.exit(0)

if __name__ == "__main__":
    main()

