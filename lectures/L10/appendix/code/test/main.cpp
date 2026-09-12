/**
 * @file Unit test entry point.
 */
#include <cstdio>

#include "qacademy/test/test.hpp"

/**
 * @brief Run all registered test cases.
 *
 *        The test cases sit behind the L01 macro. Until that macro is defined no test cases
 *        are registered, so the run is skipped rather than reported as a failure
 *        (runAllTests() treats an empty registry as an error, which is the right behaviour
 *        once the exercise is under way).
 *
 * @return 0 if every test passed, -1 otherwise.
 */
int main()
{
#ifdef L01
    return qacademy::test::runAllTests() ? 0 : -1;
#else
    std::printf("L01 unit tests are disabled. Add -DL01 to CXX_FLAGS in the Makefile.\n");
    return 0;
#endif
}
