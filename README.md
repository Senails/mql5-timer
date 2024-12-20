This is my implementation of the possibility of serialization and deserialization of json in the mql5 language

example:

```mql5
#include "index.mqh";

ulong intervalId;

void OnInit() {
    // Only for Experts and Indicators
    Timer::setTimout(myCallback2, 1000); // after 1000ms
    Timer::setTimout(myCallback1, 500); // after 500ms
    intervalId = Timer::setInterval(myCallback4, 800, "myCallback4 800"); // every 800ms
}

void myCallback1() {
    Print("myCallback 500");
    Timer::setTimout(myCallback3, 600); // after 600ms
}

void myCallback2() {
    Print("myCallback 1000");
}

void myCallback3() {
    Print("myCallback 1100");
}

void myCallback4(string param) {
    Print(param);
    Timer::clearInterval(intervalId);
}

// myCallback 500
// myCallback4 800
// myCallback 1000
// myCallback 1100
```
