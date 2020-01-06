#define TEST_ATTRIBUTE
#define attribute_deprecated __attribute__((deprecated))

#define test(a, b) this(a, b)

void *magic;

struct test {
#ifdef TEST_ATTRIBUTE
    int test1;
#else
    float test1;
#endif
};
