#include <stdlib.h>
#include <unistd.h>

int main() {
    setenv("GSETTINGS_SCHEMA_DIR", "./data", 1);
    execl("./builddir/com.github.phase1geo.minder", "com.github.phase1geo.minder", NULL);
    return 1;
}
