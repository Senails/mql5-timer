template<typename T>
class TypedTimer {
    typedef void (*TimerCallbackWithoutParam)();
    typedef void (*TimerCallbackWithParam)(T);
    typedef void (*TimerCallbackWithParamAndId)(T, ulong);

    class Task;
public:
    static ulong setTimeout(TimerCallbackWithParam callback, int ms, T param) {
        return new Task(callback, ms, false, param).id;
    }
    static ulong setTimeout(TimerCallbackWithoutParam callback, int ms) {
        return new Task(callback, ms, false).id;
    }
    static void clearTimeout(ulong id) {
        TimerController::removeTaskFromListById(id, true);
    }

    static ulong setInterval(TimerCallbackWithParamAndId callback, int ms, T param) {
        return new Task(callback, ms, true, param).id;
    }
    static ulong setInterval(TimerCallbackWithParam callback, int ms, T param) {
        return new Task(callback, ms, true, param).id;
    }
    static ulong setInterval(TimerCallbackWithoutParam callback, int ms) {
        return new Task(callback, ms, true).id;
    }
    static void clearInterval(ulong id) {
        TimerController::removeTaskFromListById(id, true);
    }

private:
    TypedTimer() {};

    class Task: public TimerController::BaseTimerTask {
    public:
        bool withParam;
        bool withId;
        T param;

        TimerCallbackWithoutParam callbackWithoutParam;
        TimerCallbackWithParam callbackWithParam;
        TimerCallbackWithParamAndId callbackWithParamAndId;

        Task(TimerCallbackWithParamAndId c, int ms, bool i, T p): BaseTimerTask(ms, i), callbackWithParamAndId(c), param(p), withId(true) {
            TimerController::insertTaskToList(&this);
            TimerController::updateTimer();
        };
        Task(TimerCallbackWithParam c, int ms, bool i, T p): BaseTimerTask(ms, i), callbackWithParam(c), param(p), withParam(true) {
            TimerController::insertTaskToList(&this);
            TimerController::updateTimer();
        };
        Task(TimerCallbackWithoutParam c, int ms, bool i): BaseTimerTask(ms, i), callbackWithoutParam(c) {
            TimerController::insertTaskToList(&this);
            TimerController::updateTimer();
        };
    
        virtual void execute() override {
            if (this.withId) {
                this.callbackWithParamAndId(this.param, this.id);
                return;
            }
            if (this.withParam) {
                this.callbackWithParam(this.param);
                return;
            }
            this.callbackWithoutParam();
        }
    };
};

class TimerController {
    class BaseTimerTask;
    static BaseTimerTask* taskList[];
public:
    ~TimerController() {
        for (int i = 0; i < ArraySize(TimerController::taskList); i++) delete TimerController::taskList[i];
    }

    static void insertTaskToList(BaseTimerTask* task) {
        int size = ArraySize(TimerController::taskList);
        ArrayResize(TimerController::taskList, size + 1, MathMax(size/10, 10));

        for (int i = size; i > 0; i--) {
            if (TimerController::taskList[i-1].date <= task.date) {
                TimerController::taskList[i] = task;
                return;
            }
            TimerController::taskList[i] = TimerController::taskList[i-1];
        }

        TimerController::taskList[0] = task;
    }
    static void removeTaskFromListById(ulong id, bool cleanMemory = false) {
        int size = ArraySize(TimerController::taskList);
        for (int i = 0; i < size; i++) {
            if (TimerController::taskList[i].id == id) {
                if (cleanMemory) delete TimerController::taskList[i];

                for (int j = i; j < size - 1; j++) {
                    TimerController::taskList[j] = TimerController::taskList[j + 1];
                }
                ArrayResize(TimerController::taskList, size - 1, MathMax(size/10, 10));
                return;
            }
        }
    }
    static void updateTimer() {
        EventKillTimer();
        if (ArraySize(TimerController::taskList) == 0) return;
        int timeToNextTask = int(TimerController::taskList[0].date - GetTickCount64());
        EventSetMillisecondTimer(MathMax(timeToNextTask, 1));
    }
    static void handleTimerEvent() {
        while (ArraySize(TimerController::taskList) > 0) {
            BaseTimerTask* task = TimerController::taskList[0];
            ulong now = GetTickCount64();

            if (task.date > now) break;
            TimerController::removeTaskFromListById(task.id);

            if (task.interval) {
                task.date += task.time;
                TimerController::insertTaskToList(task);
                task.execute();
                continue;
            }

            task.execute();
            delete task;
        }

        TimerController::updateTimer();
    }

    class BaseTimerTask {
        static ulong idCounter;
    public:
        ulong id;
        int time;
        ulong date;
        bool interval;

        BaseTimerTask(int ms, bool i): id(idCounter++), time(ms), interval(i) {
            this.date = GetTickCount64() + MathMax(16, ms);
        };

        virtual void execute() {};
    };
};

class Timer: public TypedTimer<string> {};

ulong TimerController::BaseTimerTask::idCounter = 0;
TimerController::BaseTimerTask* TimerController::taskList[];
TimerController timerController;
void OnTimer() { TimerController::handleTimerEvent(); };
