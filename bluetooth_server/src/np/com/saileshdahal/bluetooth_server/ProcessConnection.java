package np.com.saileshdahal.bluetooth_server;

import static java.awt.event.KeyEvent.*;

import java.awt.MouseInfo;
import java.awt.Point;
import java.awt.Robot;
import java.awt.event.InputEvent;
import java.awt.event.KeyEvent;
import java.io.IOException;
import java.io.InputStream;
import javax.microedition.io.StreamConnection;

public class ProcessConnection implements Runnable {

  private StreamConnection mConnection;

  private static final int EXIT_CMD = -1;

  Robot robot;

  private boolean threadStop = false;
  private InputStream inputStream;

  void setThreadStopper(boolean threadStop) {
    this.threadStop = threadStop;
    if (threadStop) {
      try {
        inputStream.close();
        mConnection.close();
      } catch (IOException e) {
        e.printStackTrace();
      }
    }
  }

  public ProcessConnection(StreamConnection connection) {
    mConnection = connection;
  }

  @Override
  public void run() {
    try {
      inputStream = mConnection.openInputStream();

      System.out.println("waiting for input");
      joystick.start();
      StringBuffer stringBuf = new StringBuffer();
      while (true && !threadStop) {
        int command = inputStream.read();
        if (command == EXIT_CMD) {
          System.out.println("finish process");
          break;
        }

        char a = (char) command;
        if (a == '\n') {
          processCommand(stringBuf.toString());
          stringBuf = new StringBuffer();
        } else {
          stringBuf.append(a);
        }
      }
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

  class Joystick extends Thread {

    double inRadians;

    public Joystick(double radians) {
      this.inRadians = radians;
    }

    void setRadians(double radians) {
      this.inRadians = radians;
    }

    @Override
    public void run() {
      while (true && !threadStop) {
        if (inRadians != 0) {
          int xi1, yi1, xi, yi;
          Point p = MouseInfo.getPointerInfo().getLocation();
          xi = p.x;
          yi = p.y;
          xi1 = xi + (int) (2 * Math.sin(inRadians));
          yi1 = yi - (int) (2 * Math.cos(inRadians));
          robot.mouseMove(xi1, yi1);
          try {
            sleep(1);
          } catch (InterruptedException e) {
            e.printStackTrace();
          }
        }
      }
    }
  }

  Joystick joystick = new Joystick(0);
  boolean dragStarted = false;

  /**
   * Process the command from client
   *
   * @param command the command code
   */
  private void processCommand(String command) {
    try {
      System.out.println(command);
      if (robot == null) {
        robot = new Robot();
      }
      if (command.startsWith("*#*LC*@*")) {
        robot.mousePress(InputEvent.BUTTON1_MASK);
        robot.mouseRelease(InputEvent.BUTTON1_MASK);
        return;
      }
      if (command.startsWith("*#*ZOOM")) {
        robot.keyPress(KeyEvent.VK_CONTROL);
        double x2 = Double.parseDouble(
          command.substring(7, command.indexOf("*@*"))
        );
        robot.mouseWheel((int) (x2 * 5));
        robot.keyRelease(KeyEvent.VK_CONTROL);
        return;
      }
      if (command.startsWith("*#*SCROLL")) {
        double x2 = Double.parseDouble(
          command.substring(9, command.indexOf("*@*"))
        );
        robot.mouseWheel((int) (x2 * 5));
        return;
      }

      if (command.startsWith("*#*TYPE")) {
        String keys = command.substring(7, command.indexOf("*@*"));
        type(robot, keys);
        return;
      }
      if (command.startsWith("*#*esc*@*")) {
        robot.keyPress(KeyEvent.VK_ESCAPE);
        robot.keyRelease(KeyEvent.VK_ESCAPE);
        return;
      }
      if (command.startsWith("*#*Offset")) {
        Point p = MouseInfo.getPointerInfo().getLocation();
        int xi = p.x;
        int yi = p.y;
        double x2 = Double.parseDouble(
          command.substring(10, command.indexOf(","))
        );
        double y2 = Double.parseDouble(
          command.substring(command.indexOf(",") + 1, command.indexOf(")"))
        );
        int xi1 = (int) (xi + (x2 * 5));
        int yi1 = (int) (yi + (y2 * 5));
        robot.mouseMove(xi1, yi1);

        return;
      }

      if (command.startsWith("*#*DRAGOffset")) {
        Point p = MouseInfo.getPointerInfo().getLocation();
        int xi = p.x;
        int yi = p.y;
        double x2 = Double.parseDouble(
          command.substring(14, command.indexOf(","))
        );
        double y2 = Double.parseDouble(
          command.substring(command.indexOf(",") + 1, command.indexOf(")"))
        );
        int xi1 = (int) (xi + (x2 * 5));
        int yi1 = (int) (yi + (y2 * 5));
        robot.mouseMove(xi1, yi1);
        if (!dragStarted) {
          robot.mousePress(InputEvent.BUTTON1_MASK);
          dragStarted = true;
        }
        return;
      }
      if (command.startsWith("*#*DRAGENDED*@*")) {
        robot.mouseRelease(InputEvent.BUTTON1_MASK);

        return;
      }

      int xi1, yi1, xi, yi;

      if (command.startsWith("*#*JOYSTICK")) {
        double angle = Double.parseDouble(
          command.substring(11, command.indexOf(" "))
        );
        double distance = Double.parseDouble(
          command.substring(command.indexOf(" ") + 1, command.indexOf("*@*"))
        );
        double inRadians = Math.toRadians(angle);
        joystick.setRadians(inRadians);
      }
      if (command.startsWith("*#*RIGHT*@*")) {
        robot.keyPress(KeyEvent.VK_RIGHT);
        robot.keyRelease(KeyEvent.VK_RIGHT);
      }
      if (command.startsWith("*#*UP*@*")) {
        robot.keyPress(KeyEvent.VK_UP);
        robot.keyRelease(KeyEvent.VK_UP);
      }
      if (command.startsWith("*#*DOWN*@*")) {
        robot.keyPress(KeyEvent.VK_DOWN);
        robot.keyRelease(KeyEvent.VK_DOWN);
      }
      if (command.startsWith("*#*LEFT*@*")) {
        robot.keyPress(KeyEvent.VK_LEFT);
        robot.keyRelease(KeyEvent.VK_LEFT);
      }
      if (command.startsWith("*#*F5*@*")) {
        robot.keyPress(KeyEvent.VK_F5);
        robot.keyRelease(KeyEvent.VK_F5);
      }
      if (command.startsWith("*#*SHIFT+F5*@*")) {
        robot.keyPress(KeyEvent.VK_SHIFT);
        robot.keyPress(KeyEvent.VK_F5);
        robot.keyRelease(KeyEvent.VK_SHIFT);
        robot.keyRelease(KeyEvent.VK_F5);
      }
      if (command.startsWith("*#*SPACE*@*")) {
        robot.keyPress(KeyEvent.VK_SPACE);
        robot.keyRelease(KeyEvent.VK_SPACE);
      }
      if (command.startsWith("*#*CTRL+ALT+T*@*")) {
        robot.keyPress(KeyEvent.VK_CONTROL);
        robot.keyPress(KeyEvent.VK_ALT);
        robot.keyPress(KeyEvent.VK_T);
        robot.keyRelease(KeyEvent.VK_CONTROL);
        robot.keyRelease(KeyEvent.VK_ALT);
        robot.keyRelease(KeyEvent.VK_T);
      }
      if (command.startsWith("*#*CTRL+SHIFT+T*@*")) {
        robot.keyPress(KeyEvent.VK_CONTROL);
        robot.keyPress(KeyEvent.VK_SHIFT);
        robot.keyPress(KeyEvent.VK_T);
        robot.keyRelease(KeyEvent.VK_CONTROL);
        robot.keyRelease(KeyEvent.VK_SHIFT);
        robot.keyRelease(KeyEvent.VK_T);
      }
      if (command.startsWith("*#*CTRL+L*@*")) {
        robot.keyPress(KeyEvent.VK_CONTROL);
        robot.keyPress(KeyEvent.VK_L);
        robot.keyRelease(KeyEvent.VK_CONTROL);
        robot.keyRelease(KeyEvent.VK_L);
      }
      if (command.startsWith("*#*CTRL+C*@*")) {
        robot.keyPress(KeyEvent.VK_CONTROL);
        robot.keyPress(KeyEvent.VK_C);
        robot.keyRelease(KeyEvent.VK_CONTROL);
        robot.keyRelease(KeyEvent.VK_C);
      }
      if (command.startsWith("*#*PLUS*@*")) {
        robot.keyPress(KeyEvent.VK_PLUS);
        robot.keyRelease(KeyEvent.VK_PLUS);
        return;
      }
      if (command.startsWith("*#*ENTER*@*")) {
        robot.keyPress(KeyEvent.VK_ENTER);
        robot.keyRelease(KeyEvent.VK_ENTER);
        return;
      }
      if (command.startsWith("*#*MINUS*@*")) {
        robot.keyPress(KeyEvent.VK_MINUS);
        robot.keyRelease(KeyEvent.VK_MINUS);
        return;
      }
      if (command.startsWith("*#*SINGLEKEY+")) {
        String key = command.substring(13, command.indexOf("*@*"));
        int keyCode = KeyEvent.getExtendedKeyCodeForChar(key.charAt(0));
        if (KeyEvent.CHAR_UNDEFINED == keyCode) {
          throw new RuntimeException(
            "Key code not found for character '" + key.charAt(0) + "'"
          );
        }
        robot.keyPress(keyCode);
        robot.delay(10);
        robot.keyRelease(keyCode);
        robot.delay(10);
      }
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

  void type(Robot robot, String keys) {
    for (char c : keys.toCharArray()) {
      type(c);
      robot.delay(10);
    }
  }

  public void type(char character) {
    switch (character) {
      case 'a':
        doType(VK_A);
        break;
      case 'b':
        doType(VK_B);
        break;
      case 'c':
        doType(VK_C);
        break;
      case 'd':
        doType(VK_D);
        break;
      case 'e':
        doType(VK_E);
        break;
      case 'f':
        doType(VK_F);
        break;
      case 'g':
        doType(VK_G);
        break;
      case 'h':
        doType(VK_H);
        break;
      case 'i':
        doType(VK_I);
        break;
      case 'j':
        doType(VK_J);
        break;
      case 'k':
        doType(VK_K);
        break;
      case 'l':
        doType(VK_L);
        break;
      case 'm':
        doType(VK_M);
        break;
      case 'n':
        doType(VK_N);
        break;
      case 'o':
        doType(VK_O);
        break;
      case 'p':
        doType(VK_P);
        break;
      case 'q':
        doType(VK_Q);
        break;
      case 'r':
        doType(VK_R);
        break;
      case 's':
        doType(VK_S);
        break;
      case 't':
        doType(VK_T);
        break;
      case 'u':
        doType(VK_U);
        break;
      case 'v':
        doType(VK_V);
        break;
      case 'w':
        doType(VK_W);
        break;
      case 'x':
        doType(VK_X);
        break;
      case 'y':
        doType(VK_Y);
        break;
      case 'z':
        doType(VK_Z);
        break;
      case 'A':
        doType(VK_SHIFT, VK_A);
        break;
      case 'B':
        doType(VK_SHIFT, VK_B);
        break;
      case 'C':
        doType(VK_SHIFT, VK_C);
        break;
      case 'D':
        doType(VK_SHIFT, VK_D);
        break;
      case 'E':
        doType(VK_SHIFT, VK_E);
        break;
      case 'F':
        doType(VK_SHIFT, VK_F);
        break;
      case 'G':
        doType(VK_SHIFT, VK_G);
        break;
      case 'H':
        doType(VK_SHIFT, VK_H);
        break;
      case 'I':
        doType(VK_SHIFT, VK_I);
        break;
      case 'J':
        doType(VK_SHIFT, VK_J);
        break;
      case 'K':
        doType(VK_SHIFT, VK_K);
        break;
      case 'L':
        doType(VK_SHIFT, VK_L);
        break;
      case 'M':
        doType(VK_SHIFT, VK_M);
        break;
      case 'N':
        doType(VK_SHIFT, VK_N);
        break;
      case 'O':
        doType(VK_SHIFT, VK_O);
        break;
      case 'P':
        doType(VK_SHIFT, VK_P);
        break;
      case 'Q':
        doType(VK_SHIFT, VK_Q);
        break;
      case 'R':
        doType(VK_SHIFT, VK_R);
        break;
      case 'S':
        doType(VK_SHIFT, VK_S);
        break;
      case 'T':
        doType(VK_SHIFT, VK_T);
        break;
      case 'U':
        doType(VK_SHIFT, VK_U);
        break;
      case 'V':
        doType(VK_SHIFT, VK_V);
        break;
      case 'W':
        doType(VK_SHIFT, VK_W);
        break;
      case 'X':
        doType(VK_SHIFT, VK_X);
        break;
      case 'Y':
        doType(VK_SHIFT, VK_Y);
        break;
      case 'Z':
        doType(VK_SHIFT, VK_Z);
        break;
      case '`':
        doType(VK_BACK_QUOTE);
        break;
      case '0':
        doType(VK_0);
        break;
      case '1':
        doType(VK_1);
        break;
      case '2':
        doType(VK_2);
        break;
      case '3':
        doType(VK_3);
        break;
      case '4':
        doType(VK_4);
        break;
      case '5':
        doType(VK_5);
        break;
      case '6':
        doType(VK_6);
        break;
      case '7':
        doType(VK_7);
        break;
      case '8':
        doType(VK_8);
        break;
      case '9':
        doType(VK_9);
        break;
      case '-':
        doType(VK_MINUS);
        break;
      case '=':
        doType(VK_EQUALS);
        break;
      case '~':
        doType(VK_SHIFT, VK_BACK_QUOTE);
        break;
      case '!':
        doType(VK_EXCLAMATION_MARK);
        break;
      case '@':
        doType(VK_AT);
        break;
      case '#':
        doType(VK_NUMBER_SIGN);
        break;
      case '$':
        doType(VK_DOLLAR);
        break;
      case '%':
        doType(VK_SHIFT, VK_5);
        break;
      case '^':
        doType(VK_CIRCUMFLEX);
        break;
      case '&':
        doType(VK_AMPERSAND);
        break;
      case '*':
        doType(VK_ASTERISK);
        break;
      case '(':
        doType(VK_LEFT_PARENTHESIS);
        break;
      case ')':
        doType(VK_RIGHT_PARENTHESIS);
        break;
      case '_':
        doType(VK_UNDERSCORE);
        break;
      case '+':
        doType(VK_PLUS);
        break;
      case '\t':
        doType(VK_TAB);
        break;
      case '\n':
        doType(VK_ENTER);
        break;
      case '[':
        doType(VK_OPEN_BRACKET);
        break;
      case ']':
        doType(VK_CLOSE_BRACKET);
        break;
      case '\\':
        doType(VK_BACK_SLASH);
        break;
      case '{':
        doType(VK_SHIFT, VK_OPEN_BRACKET);
        break;
      case '}':
        doType(VK_SHIFT, VK_CLOSE_BRACKET);
        break;
      case '|':
        doType(VK_SHIFT, VK_BACK_SLASH);
        break;
      case ';':
        doType(VK_SEMICOLON);
        break;
      case ':':
        doType(VK_COLON);
        break;
      case '\'':
        doType(VK_QUOTE);
        break;
      case '"':
        doType(VK_QUOTEDBL);
        break;
      case ',':
        doType(VK_COMMA);
        break;
      case '<':
        doType(VK_SHIFT, VK_COMMA);
        break;
      case '.':
        doType(VK_PERIOD);
        break;
      case '>':
        doType(VK_SHIFT, VK_PERIOD);
        break;
      case '/':
        doType(VK_SLASH);
        break;
      case '?':
        doType(VK_SHIFT, VK_SLASH);
        break;
      case ' ':
        doType(VK_SPACE);
        break;
      default:
        throw new IllegalArgumentException(
          "Cannot type character " + character
        );
    }
  }

  private void doType(int... keyCodes) {
    doType(keyCodes, 0, keyCodes.length);
  }

  private void doType(int[] keyCodes, int offset, int length) {
    if (length == 0) {
      return;
    }

    robot.keyPress(keyCodes[offset]);
    doType(keyCodes, offset + 1, length - 1);
    robot.keyRelease(keyCodes[offset]);
  }
}
