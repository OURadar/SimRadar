//
//  lsiq.c
//  List IQ files
//
//  Created by Boon Leng Cheong.
//  Copyright (c) 2016 Boon Leng Cheong. All rights reserved.
//
//

#include "rs.h"
#include "iq.h"

#include <errno.h>

#include <dirent.h>

#define UNDERLINE(x)  "\033[4m" x "\033[24m"

int main(int argc, char **argv) {

    int k;
    struct dirent *dir;
    struct stat file_stat;
    
    DIR *d;
    char path[1024];
    char filename[1024];
    
    FILE *f;
    
    IQFileHeader file_header;

    if (argc > 1) {
        printf("argv[1] =  %s\n", argv[1]);
    }
    
    if (argc == 1) {
        sprintf(path, ".");
    } else {
        if (argv[1][0] == '~') {
            strcpy(path, getenv("HOME"));
            strcat(path, &argv[1][1]);
            printf("path = %s\n", path);
        } else {
            strcpy(path, argv[1]);
        }
    }
    
    d = opendir(path);

    if (d == NULL) {
        fprintf(stderr, "Directory does not exists.\n");
        return EXIT_FAILURE;
    }

    k = 0;
    while ((dir = readdir(d)) != NULL) {
        if (dir->d_namlen < 3 || strstr(dir->d_name, ".iq") == NULL) {
            continue;
        }
        sprintf(filename, "%s/%s", path, dir->d_name);
        if (stat(filename, &file_stat) < 0) {
            printf("%s\n", strerror(errno));
        }
        f = fopen(filename, "r");
        fread(&file_header, sizeof(file_header), 1, f);
        fclose(f);
        printf("%s   %6s B   %d\n", dir->d_name, commaint(file_stat.st_size), file_header.simulation_seed);
        k++;
    }
    
    if (k == 0) {
        printf("No files.\n");
    }
    
    closedir(d);
    
    return EXIT_SUCCESS;
}
