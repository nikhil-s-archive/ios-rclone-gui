#ifndef librclone_h
#define librclone_h

#include <stdint.h>

struct RcloneRPCResult {
    char *Output;
    int Status;
};

struct RcloneRPCResult RcloneRPC(const char *method, const char *input);
void RcloneFreeString(char *str);

#endif /* librclone_h */
