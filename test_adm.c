//
//  test_adm.c
//
//  Created by Boon Leng Cheong on 1/19/15.
//  Copyright (c) 2015 Boon Leng Cheong. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include "adm.h"

int main(int argc, const char **argv) {
    
    printf("Testing ADM table reading ...\n");
    
    ADMTable *table;
    
    ADMHandle *A = ADM_init();
    
    if (A == NULL) {
        return EXIT_FAILURE;
    }

    table = ADM_get_table(A, ADMConfigModelPlate);
    ADM_show_table_summary(table);
    
    ADM_free(A);
    
    return EXIT_SUCCESS;
}
