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
    char *keyString;
    int level;
    void *value;
    struct SLNode **next;
};

// maxlevels is the max depth of this skiplist
struct SLNode *newSLNode(int maxLevels, int level)
{
    struct SLNode *node = malloc(sizeof *node);
    node->keyString = NULL;
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
    if(node -> keyString) free(node->keyString);
    free(node->next);
    free(node);
}

struct SkipList {
    struct SLNode *head;
    int maxLevels;
    int level;
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
    list->maxLevels = maxLevels;
    list->level = 1;
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
    free(list);
}

struct SkipListSearch {
    struct SkipList *parent;
    struct SLNode **update;
    int ok;
};

struct SkipListSearch *newSkipListSearch(struct SkipList *parent)
{
    struct SkipListSearch *search = malloc(sizeof *search);
    search->parent = parent;
    search->update = malloc(parent->maxLevels * sizeof (struct SLNode));
    search->ok = 0;
    
    int i;
    for(i = 0; i < parent->maxLevels; i++)
        search->update[i] = NULL;

    return search;
}

void destroySkipListSearch(struct SkipListSearch *search)
{
    free(search->update);
    free(search);
}

int searchSkipListString(struct SkipList *list, struct SkipListSearch *search, char *keyString)
{
    struct SLNode *x = list->head;
    int i;
    
    for(i = list->level; i >= 1; i--) {
        while(x->next[i-1] != NULL && strcmp(x->next[i-1]->keyString, keyString) < 0) {
            x = x->next[i-1];
        }
        search->update[i-1] = x;
        i -= 1;
    }
    return search->ok = x->next[i-1] != NULL;
}

int searchMatchedExactString(struct SkipListSearch *search, char *keyString)
{
    if(!search->ok) return 0;
    if(search->update[0] == NULL) return 0;

    return strcmp(search->update[0]->keyString, keyString) == 0;
}

char *getMatchedKeyString(struct SkipListSearch *search)
{
    if(!search->ok) return NULL;
    if(search->update[0] == NULL) return NULL;
    
    return search->update[0]->keyString;
}

void *getMatchedValue(struct SkipListSearch *search)
{
    if(!search->ok) return NULL;
    if(search->update[0] == NULL) return NULL;

    return search->update[0]->value;
}

int setMatchedValue(struct SkipListSearch *search, void *value)
{
    if(!search->ok) return 0;
    if(search->update[0] == NULL) return 0;
    
    search->update[0]->value = value;
    return 1;
}

// Generic insert for all types
int insertBeforePossibleMatch(struct SkipListSearch *search, struct SLNode *newNode, int level)
{
    struct SkipList *list = search->parent;
    if(!search->ok) return 0;
    search->ok = 0;
    
    // If the new node is higher than the current level, fill up the update[] list
    // with head
    while(level > list->level) {
        list->level += 1;
        search->update[list->level-1] = list->head;
    }
    
    // patch new node in to the saved nodes in the update[] list
    int i;
    for(i = 1; i <= level; i ++) {
        newNode->next[i-1] = search->update[i-1]->next[i-1];
        search->update[i-1]->next[i-1] = newNode;
    }
    return 1;
}

// Specific insert for string
int insertBeforePossibleMatchString(struct SkipListSearch *search, char *keyString, void *value)
{
    struct SkipList *list = search->parent;
    if(!search->ok) return 0;

    // Pick a random level for the new node
    int level = randomLevel(list->maxLevels);

    // Create the new node
    struct SLNode *newNode = newSLNode(list->maxLevels, level);
    strcpy(newNode->keyString = malloc(strlen(keyString) + 1), keyString);
    newNode -> value = value;
    
    // Call the general routine for the tricky stuff
    if (!insertBeforePossibleMatch(search, newNode, level)) { // can't happen
        destroySLNode(newNode);
        return 0;
    }
    return 1;
}

int deleteMatchedNode(struct SkipListSearch *search)
{
    struct SkipList *list = search->parent;
    if(!search->ok) return 0;
    search->ok = 0;
    
    struct SLNode *x = search->update[0];
    
    // point all the previous node to the new next node
    int i;
    for(i = 1; i < list->level; i ++) {
        if(search->update[i-1]->next[i-1] != x)
            break;
        search->update[i-1]->next[i-1] = x->next[i-1];
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