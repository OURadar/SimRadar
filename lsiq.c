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

int cstring_cmp(const void *a, const void *b)
{
    const char **ia = (const char **)a;
    const char **ib = (const char **)b;
    return strcmp(*ia, *ib);
}

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
    
    char *filelist[4096];

    // Truncate the last path delimeter
    if (path[strlen(path) - 1] == '/') {
        path[strlen(path) - 1] = '\0';
    }
    
    d = opendir(path);

    if (d == NULL) {
        fprintf(stderr, "Directory does not exists.\n");
        return EXIT_FAILURE;
    }
    
    k = 0;
    while ((dir = readdir(d)) != NULL) {
        if (strlen(dir->d_name) < 3 || strstr(dir->d_name, ".iq") == NULL) {
            continue;
        }
        filelist[k] = (char *)malloc(strlen(dir->d_name) + 1);
        strcpy(filelist[k], dir->d_name);
        k++;
    }
    
    closedir(d);

    if (k == 0) {
        printf("No files.\n");
        return EXIT_SUCCESS;
    }
    
    const int nfiles = k;
    
    //printf("nfiles = %d\n", nfiles);

    qsort(filelist, nfiles, sizeof(char *), cstring_cmp);
    
    for (k = 0; k < nfiles; k++) {
        sprintf(filename, "%s/%s", path, filelist[k]);
        if (stat(filename, &file_stat) < 0) {
            printf("%s\n", strerror(errno));
        }
        f = fopen(filename, "r+");
        fread(&file_header, sizeof(file_header), 1, f);
        printf("%s   %6s B   %d\n", filelist[k], commaint(file_stat.st_size), file_header.simulation_seed);
//        file_header.simulation_seed = k + 1825;
//        rewind(f);
//        fwrite(&file_header, sizeof(file_header), 1, f);
//        fseek(f, 0, SEEK_END);
        free(filelist[k]);
        fclose(f);
    }
    
    
    return EXIT_SUCCESS;
}
