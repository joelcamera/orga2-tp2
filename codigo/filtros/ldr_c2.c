
#include "../tp2.h"

#define MIN(x,y) ( x < y ? x : y )
#define MAX(x,y) ( x > y ? x : y )

#define MAXSUMA 4876875.0 //5*5*255*3*255

void ldr_c2    (
    unsigned char *src,
    unsigned char *dst,
    int cols,
    int filas,
    int src_row_size,
    int dst_row_size,
    int alpha)
{
    unsigned char (*src_matrix)[src_row_size] = (unsigned char (*)[src_row_size]) src;
    unsigned char (*dst_matrix)[dst_row_size] = (unsigned char (*)[dst_row_size]) dst;
    int buffer[5][src_row_size];
    memset(buffer, 0, sizeof(int)*5*src_row_size);

    //precalcular primer columna
    int presuma[5] = {0,0,0,0,0};
    int presumaActual = 0;
    int suma = 0;
    
    bgra_t *p_s, *p_d;
    int sumargb;
    float axSumargb;

    for (int i = 0; i < filas; i++) {

        suma = 0;
        presuma[0] = 0;
        presuma[1] = 0;
        presuma[2] = 0;
        presuma[3] = 0;
        presuma[4] = 0;

        for (int j = 0; j < cols; j++) {
            p_s = (bgra_t*) &src_matrix[i][j * 4];
            presumaActual = p_s->r + p_s->g + p_s->b;
            suma -= presuma[j % 5];
            suma += presumaActual;
            presuma[j % 5] = presumaActual;

            if(j >= 4) {
                buffer[i % 5][(j-2)] = suma;

                if(i >= 4) {
                    
                    sumargb = 0;
                    for (int k = 0; k < 5; k++) {
                        sumargb += buffer[k][(j-2)];
                    }
                    
                    axSumargb = (alpha * sumargb) / MAXSUMA;
                    p_s = (bgra_t*) &src_matrix[i - 2][(j - 2) * 4];
                    p_d = (bgra_t*) &dst_matrix[i - 2][(j - 2) * 4];

                    int sumargbCanalR = p_s->r + (axSumargb * p_s->r);
                    int sumargbCanalG = p_s->g + (axSumargb * p_s->g);
                    int sumargbCanalB = p_s->b + (axSumargb * p_s->b);
                    p_d->r = MIN(MAX(sumargbCanalR, 0), 255);
                    p_d->g = MIN(MAX(sumargbCanalG, 0), 255);
                    p_d->b = MIN(MAX(sumargbCanalB, 0), 255);


                }
            }
        }

    }

}
