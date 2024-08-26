This PowerShell script sets up a custom UDP server to monitor network traffic 
by receiving UDP packets, tracking IP addresses, and logging their activity in a JSON file. 
It maintains an up-to-date record of active IP addresses and their last interaction with 
the server, automatically removing entries for inactive IPs after 5 minutes of no activity.

Features

	•	UDP Packet Reception: Listens for incoming UDP packets on a specified port.
	•	Real-Time Logging: Logs received packets and connection details to a log file.
	•	Active IP Tracking: Monitors and updates the list of IP addresses with their last activity timestamp.
	•	JSON Storage: Saves IP addresses and their last activity times in a JSON file formatted as DD-HH-MM.
	•	Automatic Cleanup: Removes IP addresses that have been inactive for more than 5 minutes from the JSON file.

Usage

	1.	Configure the Script: Adjust the parameters for the port, log file, and JSON file as needed. For example:
   	
		Start-UDPLogger -Port 1194 -LogFile "C:\Logs\udpserver.log" -JsonFile "C:\Logs\active_ips.json"
     
	2.	Run the Script: Execute the script to start the UDP server. The server will begin listening for UDP packets on the specified port and log each received packet, along with the IP address and timestamp.
	3.	Monitor the Log and JSON Files:
	    •	The log file will contain a record of all received packets with timestamps.
	    •	The JSON file will maintain a list of active IP addresses and the last time they communicated with the server. Inactive IPs are automatically removed after 5 minutes.

Use Cases

	•	Network Monitoring: Track and log incoming UDP traffic for real-time monitoring of network activity.
	•	Security Auditing: Maintain a record of devices communicating with your server, useful for detecting unauthorized access or unusual activity.
	•	Diagnostic Tool: Use the tool for troubleshooting network issues by analyzing which IP addresses are actively sending data.
	•	Custom Monitoring Solutions: Integrate this script into larger network management or monitoring systems to track and log UDP communications.

  	
