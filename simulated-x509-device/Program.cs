using System;
using Microsoft.Azure.Devices.Client;
using Microsoft.Azure.Devices.Shared;
using System.Security.Cryptography.X509Certificates;
using System.Threading.Tasks;
using System.Text;
using System.IO;

namespace simulated_x509_device
{
    class Program
    {
        private static int MESSAGE_COUNT = 5;
        private static float temperature;
        private static float humidity;
        private static Random rnd = new Random();

        private static string deviceId;
        private static int temperatureThreshold = 35;
        private static int humidityThreshold = 85;
        static void Main(string[] args)
        {
            deviceId = args[0];
            string iotHub=args[1];
            string gatewayHostname=args[2];
            string deviceCert=args[3];
            string caCertPath = args[4];

            Console.WriteLine("Usage ./simulated-x509-device <device_id> <iot hub> <edgeGatewayHostame|NoGateway> <deviceCertificate> <ca root certificate>");
            Console.WriteLine("Example ./simulated-x509-device edge1-ups1 iot-playground-devices-hub.azure-devices.net iot-playground-edge1-vm upstreamCerts/iot-device-edge1-ups1.cert.pfx upstreamCerts/azure-iot-test-only.root.ca.cert.pem");

            try
            {
                InstallCACert(caCertPath);

                var cert = new X509Certificate2(deviceCert, "");
                var auth = new DeviceAuthenticationWithX509Certificate(deviceId, cert);

                DeviceClient deviceClient=null;
                if(String.IsNullOrWhiteSpace(gatewayHostname) || String.Equals(gatewayHostname, "NoGateway", StringComparison.InvariantCultureIgnoreCase))
                {
                    deviceClient = DeviceClient.Create(iotHub, auth, TransportType.Amqp_Tcp_Only);
                }
                else{
                    deviceClient = DeviceClient.Create(iotHub, gatewayHostname, auth, TransportType.Amqp_Tcp_Only);
                }

                if (deviceClient == null)
                {
                    Console.WriteLine("Failed to create DeviceClient!");
                }
                else
                {
                    Console.WriteLine("Successfully created DeviceClient!");
                    //SendEvent(deviceClient).Wait();
                    SendContinuousEvents(deviceClient).Wait();
                }

                Console.WriteLine("Exiting...\n");
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error in sample: {0}", ex.Message);
            }
        }

        static void SetThresholds(int newTemperatureThresold, int newHumidityThreshold){
            temperatureThreshold = newTemperatureThresold;
            humidityThreshold = newHumidityThreshold;
        }
        static async Task SendEvents(DeviceClient deviceClient)
        {
            Console.WriteLine("Device sending {0} messages to IoTHub...\n", MESSAGE_COUNT);

            for (int count = 0; count < MESSAGE_COUNT; count++)
            {
                await SendEvent(deviceClient, count);
            }
        }

        static async Task SendContinuousEvents(DeviceClient deviceClient)
        {
            Console.WriteLine("Device sending messages to IoTHub...\n");

            int msgCount = 1;
            while(true)
            {
                int delay=rnd.Next(500, 2500);
                await SendEvent(deviceClient, msgCount);
                msgCount++;
                await Task.Delay(delay);
            }
        }

        private static async Task SendEvent(DeviceClient deviceClient, int msgId)
        {
            temperature = rnd.Next(20, 42);
            humidity = rnd.Next(40, 90);
            
            string dataBuffer = $"{{\"deviceId\":\"{deviceId}\",\"sourceTimeStamp\":\"{DateTime.Now.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")}\",\"messageId\":{msgId},\"temperature\":{temperature},\"humidity\":{humidity}}}";
            
            Message eventMessage = new Message(Encoding.UTF8.GetBytes(dataBuffer));
            eventMessage.Properties.Add("temperatureAlert", (temperature > temperatureThreshold) ? "true" : "false");
            eventMessage.Properties.Add("humidityAlert", (humidity > humidityThreshold) ? "true" : "false");
            Console.WriteLine("\t{0}> Sending message: {1}, Data: [{2}]", DateTime.Now.ToLocalTime(), msgId, dataBuffer);

            await deviceClient.SendEventAsync(eventMessage);
        }

        static void InstallCACert(string caCertPath)
        {
            string trustedCACertPath = caCertPath;
            if (!string.IsNullOrWhiteSpace(trustedCACertPath))
            {
                Console.WriteLine("User configured CA certificate path: {0}", trustedCACertPath);
                if (!File.Exists(trustedCACertPath))
                {
                    // cannot proceed further without a proper cert file
                    Console.WriteLine("Certificate file not found: {0}", trustedCACertPath);
                    throw new InvalidOperationException("Invalid certificate file.");
                }
                else
                {
                    Console.WriteLine("Attempting to install CA certificate: {0}", trustedCACertPath);
                    X509Store store = new X509Store(StoreName.Root, StoreLocation.CurrentUser);
                    store.Open(OpenFlags.ReadWrite);
                    store.Add(new X509Certificate2(X509Certificate.CreateFromCertFile(trustedCACertPath)));
                    Console.WriteLine("Successfully added certificate: {0}", trustedCACertPath);
                    store.Close();
                }
            }
            else
            {
                Console.WriteLine("CA Path  was not set or null, not installing any CA certificate");
            }
        }
    }
}
