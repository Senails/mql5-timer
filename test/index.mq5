#include "../index.mqh";

ulong intervalId; // id for cancel

void OnInit(void) {
    Timer::setTimeout(Callback1, 3000, "321"); // after 3000ms
    Timer::setTimeout(Callback2, 2000); // after 2000ms

    intervalId = Timer::setInterval(myCallback3, 800, "myCallback4 800"); // every 800ms

    // any type of param
    TypedTimer<int>::setTimeout(Callback4, 1000, 123); // after 1000ms
    TypedTimer<string>::setInterval(myCallback5, 1800, "myCallback4 1800"); // every 800ms
}

void Callback1(string value) {
    Print("Called with value: ", value);
}
void Callback2() {
    Print("Called with value: ", "void");
}
void myCallback3(string param) {
    Print(param);
}

void Callback4(int value) {
    Print("Called with value: ", value);
    Timer::clearInterval(intervalId);
}
void myCallback5(string param, ulong idForCancel) {
    Print(param);
    Timer::clearInterval(idForCancel);
}
