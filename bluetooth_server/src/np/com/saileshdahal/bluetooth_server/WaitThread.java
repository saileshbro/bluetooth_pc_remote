package np.com.saileshdahal.bluetooth_server;

import java.io.IOException;
import javax.bluetooth.DiscoveryAgent;
import javax.bluetooth.LocalDevice;
import javax.bluetooth.UUID;
import javax.microedition.io.Connector;
import javax.microedition.io.StreamConnection;
import javax.microedition.io.StreamConnectionNotifier;

public class WaitThread implements Runnable {

  private boolean threadStop = false;

  ProcessConnection processConnection;

  public WaitThread() {}

  void setThreadStopper(boolean threadStop) {
    this.threadStop = threadStop;
    if (processConnection != null) processConnection.setThreadStopper(
      threadStop
    );
    if (threadStop) {
      try {
        notifier.close();
        if (connection != null) {
          connection.close();
        }
      } catch (IOException e) {
        e.printStackTrace();
      }
    }
  }

  @Override
  public void run() {
    waitForConnection();
  }

  private StreamConnection connection = null;
  private StreamConnectionNotifier notifier;
  LocalDevice local = null;

  private void waitForConnection() {
    try {
      local = LocalDevice.getLocalDevice();
      if (local.getDiscoverable() != DiscoveryAgent.GIAC) {
        local.setDiscoverable(DiscoveryAgent.GIAC);
      }

      UUID uuid = new UUID(80087355); // "04c6093b-0000-1000-8000-00805f9b34fb"
      String url =
        "btspp://localhost:" + uuid.toString() + ";name=RemoteBluetooth";
      notifier = (StreamConnectionNotifier) Connector.open(url);
    } catch (Exception e) {
      e.printStackTrace();
      return;
    }
    try {
      System.out.println("waiting for connection...");
      connection = notifier.acceptAndOpen();
      processConnection = new ProcessConnection(connection);
      Thread processThread = new Thread(processConnection);
      processThread.start();
    } catch (Exception e) {
      e.printStackTrace();
      return;
    }
  }
}
