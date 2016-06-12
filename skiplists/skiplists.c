//
//  skiplists.c
//  skiplists
//
//  Created by Peter da Silva on 6/11/16.
//  Copyright © 2016 Flightaware. All rights reserved.
//

#include "skiplists.h"

double randomProbability = 0.5;

int randomLevel(int maxLevels)
{
    int newLevel = 1;
    while(drand48() < randomProbability && newLevel < maxLevels) {
        newLevel += 1;
    }
    return newLevel;
}

struct SLNode {
    char *key;
    int level;
    void *value;
    struct SLNode **next;
};

// maxlevels is the max depth of this skiplist
struct SLNode *newSLNode(int maxLevels, int level)
{
    struct SLNode *node = malloc(sizeof *node);
    node->key = NULL;
    node->value = NULL;
    node -> level = level;
    node->next = malloc(maxLevels * sizeof node);

    int i;
    for(i = 0; i < maxLevels; i++)
        node->next[i] = NULL;

    return node;
}

void destroySLNode(struct SLNode *node)
{
    if(node -> key) free(node->key);
    free(node->next);
    free(node);
}

struct SkipList {
    struct SLNode *head;
    struct SLNode *update;
    int maxLevels;
    int level;
    int search_ok;
    int type; // reserved
};

#define SKIPLIST_UNKNOWN 0
#define SKIPLIST_STRING 1
#define SKIPLIST_INT 2
#define SKIPLIST_DOUBLE 3

struct SkipList *newSkipList(int maxLevels, int type)
{
    struct SkipList *list = malloc(sizeof *list);
    list->head = newSLNode(maxLevels, 0);
    list->update = newSLNode(maxLevels, 0);
    list->maxLevels = maxLevels;
    list->level = 1;
    list->search_ok = 0;
    list->type = type;
    return list;
}

void destroySkipList(struct SkipList *list)
{
    while(list->head) {
        struct SLNode *next = list->head->next[0];
        destroySLNode(list->head);
        list->head = next;
    }
    destroySLNode(list->update);
    free(list);
}

int searchSkipList(struct SkipList *list, char *key)
{
    struct SLNode *x = list->head;
    int i;
    
    for(i = list->level; i >= 1; i--) {
        while(x->next[i-1] != NULL && strcmp(x->next[i-1]->key, key) < 0) {
            x = x->next[i-1];
        }
        list->update->next[i-1] = x;
        i -= 1;
    }
    return list->search_ok = x->next[i-1] != NULL;
}

int searchMatchedExact(struct SkipList *list, char *key)
{
    if(!list->search_ok) return 0;
    if(list->update->next[0] == NULL) return 0;
    return strcmp(list->update->next[0]->key, key) == 0;
}

void *matchedValue(struct SkipList *list)
{
    if(!list->search_ok) return 0;
    if(list->update->next[0] == NULL) return NULL;

    return list->update->next[0]->value;
}

int insertBeforePossibleMatch(struct SkipList *list, char *key, void *value)
{
    if(!list->search_ok) return 0;
    list->search_ok = 0;
    
    // Pick a random level for the new node
    int level = randomLevel(list->maxLevels);
    
    // If the new node is higher than the current level, fill up the update[] list
    // with head
    while(level > list->level) {
        list->level += 1;
        list->update->next[list->level-1] = list->head;
    }
    
    // make a new node and patch it in to the saved nodes in the update[] list
    struct SLNode *newNode = newSLNode(list->maxLevels, level);
    strcpy(newNode->key = malloc(strlen(key) + 1), key);
    newNode -> value = value;
    
    int i;
    for(i = 1; i <= level; i ++) {
        newNode->next[i-1] = list->update->next[i-1]->next[i-1];
        list->update->next[i-1]->next[i-1] = newNode;
    }
    return 1;
}

int deleteMatchedNode(struct SkipList *list)
{
    if(!list->search_ok) return 0;
    list->search_ok = 0;
    
    struct SLNode *x = list->update->next[0];
    
    // point all the previous node to the new next node
    int i;
    for(i = 1; i < list->level; i ++) {
        if(list->update->next[i-1]->next[i-1] != x)
            break;
        list->update->next[i-1]->next[i-1] = x->next[i-1];
    }
    
    // if that was the biggest node, and we can see the end of the list from the head,
    // lower the list until we're pointing at a node
    while(list->level > 1 && list->head->next[list->level-1] == NULL) {
        list->level--;
    }
    
    // Dispose of the node, because we're doing memory management
    destroySLNode(x);
    
    return 1;
}