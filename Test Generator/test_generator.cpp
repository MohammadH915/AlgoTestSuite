#include <iostream>
#include <cstdlib>
#include <ctime>
using namespace std;

int main() {
    srand((unsigned)time(0));
    int test_case = rand() % 100;  // random number from 0 to 99
    cout << test_case << endl;
    return 0;
}
