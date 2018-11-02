#include "log.h"

#pragma mark -
#pragma mark Convenient Functions

char *commaint(long long num) {
    static int i = 7;
    static char buf[8][64];
    
    // Might need a semaphore to protect the following line
    i = i == 7 ? 0 : i + 1;
    
    int b = i;
    snprintf(buf[b], 48, "%lld", num);
    if (num >= 1000) {
        int c = (int)(strlen(buf[b]) - 1) / 3; // Number of commans
        int p = (int)(strlen(buf[b])) + c;     // End position
        int d = 1;                             // Count of digits
        buf[b][p] = '\0';
        while (p > 0) {
            p--;
            buf[b][p] = buf[b][p - c];
            if (d > 3) {
                d = 0;
                buf[b][p] = ',';
                c--;
            }
            d++;
        }
    }
    return buf[b];
}

char *commafloat(float num) {
    static int i = 7;
    static char buf[8][64];
    i = i == 7 ? 0 : i + 1;
    int b = i;
    snprintf(buf[b], 64, "%s.%02d", commaint(num), (int)roundf(100.0f * (num - floorf(num))));
    return buf[b];
}

// Here is a nice reference: http://www.cplusplus.com/ref/ctime/time.html
char *now() {
    static char timestr[64];
    time_t utc;
    time(&utc);
    strftime(timestr, 63, "%H:%M:%S", localtime(&utc));
    return timestr;
}


char *nowlong() {
    static char timestr[64];
    time_t utc;
    time(&utc);
    strftime(timestr, 63, "%Y%m%d-%H%M%S", localtime(&utc));
    return timestr;
}


char *nowlongoffset(const int offset) {
    static char timestr[64];
    time_t utc;
    time(&utc);
    utc += offset;
    strftime(timestr, 63, "%Y%m%d-%H%M%S", localtime(&utc));
    return timestr;
}


void rsprint(const char *format, ...) {
    
    char str[RS_MAX_STR] = "";
    sprintf(str, "%s : RS : ", now());
    size_t len = strlen(str);
    va_list args;
    char *msg = str + len;
    
    va_start(args, format);
    vsnprintf(msg, RS_MAX_STR - len, format, args);
    len = strlen(str);
    va_end(args);
    
    len = MIN(len, RS_MAX_STR - 2);
    if (str[len-1] != '\n') {
        str[len] = '\n';
        str[len+1] = '\0';
    }
    if (!strncmp(msg, "ERROR", 5)) {
        fprintf(stderr, "%s : RS : \033[1;4;31mERROR\033[0m%s", now(), &msg[5]);
    } else if (!strncmp(msg, "WARNING", 7)) {
        fprintf(stderr, "%s : RS : \033[1;33mWARNING\033[0m%s", now(), &msg[7]);
    } else if (!strncmp(msg, "INFO", 4)) {
        printf("%s : RS : \033[4mINFO\033[24m%s", now(), &msg[4]);
        fflush(stdout);
    } else {
        printf("%s", str);
    }
}
