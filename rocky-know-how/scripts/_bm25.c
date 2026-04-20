/*
 * rocky-know-how BM25计算核心 v1.0
 * 编译: gcc -O3 -o _bm25 _bm25.c -lm
 * 用法: cat texts.txt | ./_bm25 "查询词"
 * 输出: 索引\t原始分数\t归一化分数\n
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <math.h>
#include <time.h>

#define MAX_DOCS 1000
#define MAX_TOKENS 5000
#define MAX_LINE_LEN 20000

/* 分词 - 中英文混合 */
int tokenize(const char *text, char tokens[][50]) {
    int count = 0;
    const char *p = text;
    int word_buf[100];
    int wi = 0;
    
    while (*p && count < MAX_TOKENS) {
        unsigned char c = (unsigned char)*p;
        
        // ASCII字母数字
        if (isalnum(c)) {
            if (wi < 99) word_buf[wi++] = tolower(c);
        }
        // 中文字符 (UTF-8三字节)
        else if ((c & 0xE0) == 0xE0 && (unsigned char)p[1] >= 0x80 && (unsigned char)p[2] >= 0x80) {
            if (wi > 0) {
                word_buf[wi] = 0;
                if (wi >= 2) {
                    char w[50];
                    snprintf(w, 50, "%s", (char*)word_buf);
                    strcpy(tokens[count++], w);
                }
                wi = 0;
            }
            char han[4] = {*p, p[1], p[2], 0};
            strcpy(tokens[count++], han);
            p += 3;
            continue;
        }
        else {
            if (wi > 0) {
                word_buf[wi] = 0;
                if (wi >= 2) {
                    char w[50];
                    snprintf(w, 50, "%s", (char*)word_buf);
                    strcpy(tokens[count++], w);
                }
                wi = 0;
            }
        }
        p++;
    }
    
    if (wi > 0) {
        word_buf[wi] = 0;
        if (wi >= 2) {
            char w[50];
            snprintf(w, 50, "%s", (char*)word_buf);
            strcpy(tokens[count++], w);
        }
    }
    
    return count;
}

/* 全局数据 */
char docs[MAX_DOCS][MAX_LINE_LEN];
int doc_count = 0;

int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr, "用法: cat texts.txt | %s \"查询词\"\\n", argv[0]);
        return 1;
    }
    
    const char *query = argv[1];
    clock_t start = clock();
    
    /* 读取所有文档 */
    char line[MAX_LINE_LEN];
    while (fgets(line, sizeof(line), stdin) && doc_count < MAX_DOCS) {
        line[strcspn(line, "\n")] = 0;
        if (strlen(line) > 0) {
            strncpy(docs[doc_count], line, MAX_LINE_LEN - 1);
            docs[doc_count][MAX_LINE_LEN - 1] = 0;
            doc_count++;
        }
    }
    
    if (doc_count == 0) {
        fprintf(stderr, "没有文档输入\\n");
        return 1;
    }
    
    /* 查询分词 */
    char query_tokens[MAX_TOKENS][50];
    int qt = tokenize(query, query_tokens);
    if (qt == 0) {
        // 没有有效token，退化为简单包含检查
        for (int i = 0; i < doc_count; i++) {
            float score = strcasestr(docs[i], query) ? 1.0 : 0.0;
            printf("%d\\t%.4f\\t%.4f\\n", i, score, score);
        }
        return 0;
    }
    
    /* 计算平均长度 */
    int doc_lens[MAX_DOCS];
    int total_len = 0;
    for (int i = 0; i < doc_count; i++) {
        char t[MAX_TOKENS][50];
        doc_lens[i] = tokenize(docs[i], t);
        total_len += doc_lens[i];
    }
    float avgdl = (float)total_len / doc_count;
    if (avgdl < 1) avgdl = 1;
    
    /* BM25参数 */
    float k1 = 1.5, b = 0.75;
    
    /* 计算每个文档的BM25分数 */
    float scores[MAX_DOCS];
    for (int i = 0; i < doc_count; i++) {
        char doc_tokens[MAX_TOKENS][50];
        int dt = tokenize(docs[i], doc_tokens);
        
        float score = 0;
        for (int qi = 0; qi < qt; qi++) {
            int tf = 0;
            for (int di = 0; di < dt; di++) {
                if (strcmp(doc_tokens[di], query_tokens[qi]) == 0) tf++;
            }
            if (tf == 0) continue;
            
            /* 计算df */
            int df = 0;
            for (int j = 0; j < doc_count; j++) {
                char t[MAX_TOKENS][50];
                int tt = tokenize(docs[j], t);
                for (int k = 0; k < tt; k++) {
                    if (strcmp(t[k], query_tokens[qi]) == 0) { df++; break; }
                }
            }
            
            float idf = log((doc_count - df + 0.5) / (df + 0.5) + 1);
            float tf_component = (tf * (k1 + 1)) / (tf + k1 * (1 - b + b * dt / avgdl));
            score += idf * tf_component;
        }
        scores[i] = score;
    }
    
    /* 归一化并排序 */
    float max_score = 0;
    for (int i = 0; i < doc_count; i++) {
        if (scores[i] > max_score) max_score = scores[i];
    }
    
    /* 输出 */
    for (int i = 0; i < doc_count; i++) {
        float norm = max_score > 0 ? scores[i] / max_score : 0;
        printf("%d\t%.4f\t%.4f\n", i, scores[i], norm);
    }
    
    clock_t end = clock();
    fprintf(stderr, "BM25: %.2f ms\n", (double)(end - start) / CLOCKS_PER_SEC * 1000);
    
    return 0;
}
