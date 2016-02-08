//
//  test_rcs.c
//
//  Created by Boon Leng Cheong on 4/12/15.
//  Copyright (c) 2015 Boon Leng Cheong. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include "rcs.h"

int main(int argc, const char **argv) {
    
    printf("Testing RCS table reading ...\n");
    
    RCSTable *table;
    
    RCSHandle *R = RCS_init();
    
    if (R == NULL) {
        return EXIT_FAILURE;
    }
    
    printf("\nLeaf:\n\n");
    table = RCS_get_table(R, RCSConfigLeaf);
    RCS_show_table_summary(table);
    
    printf("\nWoodboard:\n\n");
    table = RCS_get_table(R, RCSConfigWoodBoard);
    RCS_show_table_summary(table);

    printf("\nBrick:\n\n");
    table = RCS_get_table(R, RCSConfigBrick);
    RCS_show_table_summary(table);

    RCS_free(R);
    
    return EXIT_SUCCESS;
}
