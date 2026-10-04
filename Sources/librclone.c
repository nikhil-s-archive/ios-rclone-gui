#include "librclone.h"
#include <stdlib.h>
#include <string.h>

struct RcloneRPCResult RcloneRPC(const char *method, const char *input) {
    struct RcloneRPCResult res;
    res.Status = 0;
    // Dummy response for compilation
    const char *dummy = "{}";
    res.Output = malloc(strlen(dummy) + 1);
    strcpy(res.Output, dummy);
    return res;
}

void RcloneFreeString(char *str) {
    if (str != NULL) {
        free(str);
    }
}
