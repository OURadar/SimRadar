#include <stdio.h>
#include <stdlib.h>
#include "les.h"

int main(int argc, const char **argv) {
	
    printf("Testing LES table reading ...\n");

	LESTable *table;

	//LESHandle L = LES_init();
    
    LESHandle L = LES_init_with_config_path("flat", NULL);
	
    if (L == NULL) {
        return EXIT_FAILURE;
    }
	
    LES_show_handle_summary(L);
    
    table = LES_get_frame(L, 0);
	LES_show_table_summary(table);

    table = LES_get_frame(L, 9);
    LES_show_table_summary(table);

    LES_free(L);
	
	return EXIT_SUCCESS;
}
