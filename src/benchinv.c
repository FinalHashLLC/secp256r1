// Copyright (c) 2013 Pieter Wuille
// Distributed under the MIT/X11 software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#include <stdio.h>

#include "scalar.h"
#include "scalar_impl.h"

int main() {
    secp256k1_scalar_t s;
    secp256k1_scalar_clear(&s);

    for (int i=0; i<1000000; i++) {
        s.d[0]++;
        secp256k1_scalar_inverse(&s, &s);
    }
    printf("%i\n", s.d[0]);
    return 0;
}
