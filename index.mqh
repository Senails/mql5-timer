typedef void (*TimerCallbackWithParam)(string);
typedef void (*TimerCallbackWithoutParam)();

class Timer {
private:
    class Task;

public:
    static ulong setTimeout(TimerCallbackWithParam callback, int ms, string param) {
        return new Task(callback, GetTickCount64() + ms, 0, param).id;
    }
    static ulong setTimeout(TimerCallbackWithoutParam callback, int ms) {
        return new Task(callback, GetTickCount64() + ms, 0).id;
    }
    static void clearTimout(ulong id) {
        Timer::removeTaskFromListById(id, true);
    }

    static ulong setInterval(TimerCallbackWithParam callback, int ms, string param) {
        return new Task(callback, GetTickCount64() + ms, ms > 0 ? ms : 1, param).id;
    }
    static ulong setInterval(TimerCallbackWithoutParam callback, int ms) {
        return new Task(callback, GetTickCount64() + ms, ms > 0 ? ms : 1).id;
    }
    static void clearInterval(ulong id) {
        Timer::removeTaskFromListById(id, true);
    }

    static void onTimerHandler() {
        Timer::handleTimerEvent();
    }

private:
    Timer() {}

    static Task* taskList[];

    static void insertTaskToList(Task* task) {
        int size = ArraySize(Timer::taskList);
        ArrayResize(Timer::taskList, size + 1);

        for (int i = size; i > 0; i--) {
            if (Timer::taskList[i-1].date <= task.date) {
                Timer::taskList[i] = task;
                return;
            }
            Timer::taskList[i] = Timer::taskList[i-1];
        }

        Timer::taskList[0] = task;
    }

    static void removeTaskFromListById(ulong id, bool cleanMemory = false) {
        int size = ArraySize(Timer::taskList);
        for (int i = 0; i < size; i++) {
            if (Timer::taskList[i].id == id) {
                if (cleanMemory) delete Timer::taskList[i];

                for (int j = i; j < size - 1; j++) {
                    Timer::taskList[j] = Timer::taskList[j + 1];
                }
                ArrayResize(Timer::taskList, size - 1);
                return;
            }
        }
    }

    static void updateTimer() {
        EventKillTimer();
        if (ArraySize(Timer::taskList) == 0) return;
        int timeToNextTask = int(Timer::taskList[0].date - GetTickCount64());
        EventSetMillisecondTimer(timeToNextTask > 0 ? timeToNextTask : 1);
    }

    static void handleTimerEvent() {
        while (ArraySize(Timer::taskList) > 0) {
            Task* task = Timer::taskList[0];
            ulong now = GetTickCount64();

            if (task.date > now) break;
            Timer::removeTaskFromListById(task.id);

            if (task.interval > 0) {
                task.date += task.interval;
                Timer::insertTaskToList(task);
                task.execute();
                continue;
            }

            task.execute();
            delete task;
        }

        Timer::updateTimer();
    }

    class Task {
        static ulong idCounter;
    public:
        ulong id;
        ulong date;
        int interval;

        bool withParam;
        string param;

        TimerCallbackWithParam callbackWithParam;
        TimerCallbackWithoutParam callbackWithoutParam;

        Task(TimerCallbackWithParam c, ulong d, int i, string p): callbackWithParam(c), date(d), interval(i), param(p), withParam(true), id(idCounter++) {
            Timer::insertTaskToList(&this);
            Timer::updateTimer();
        };
        Task(TimerCallbackWithoutParam c, ulong d, int i): callbackWithoutParam(c), date(d), interval(i), withParam(false), id(idCounter++) {
            Timer::insertTaskToList(&this);
            Timer::updateTimer();
        };
    
        void execute() {
            if (this.withParam) {
                this.callbackWithParam(this.param);
                return;
            }
            this.callbackWithoutParam();
        }
    };

    class TimerIniterAndDesctructor {
    public:
        TimerIniterAndDesctructor() {
            ArrayResize(Timer::taskList, 0, 10);
        }

        ~TimerIniterAndDesctructor() {
            for (int i = 0; i < ArraySize(Timer::taskList); i++) delete Timer::taskList[i];
            ArrayResize(Timer::taskList, 0);
        }
    };
    
};

ulong Timer::Task::idCounter = 0;
Timer::Task* Timer::taskList[];
Timer::TimerIniterAndDesctructor timerIniterAndDesctructor;

void OnTimer() { Timer::onTimerHandler(); };