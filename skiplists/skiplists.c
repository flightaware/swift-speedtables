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
    struct SLNode *node;
    int state;
};

#define SEARCH_STATE_NONE 0         // Not a valid search, either new or an insert/delete operation has occurred
#define SEARCH_STATE_FOUND 1        // Search is complete, and a key (may not be exact match) was found
#define SEARCH_STATE_TRAVERSE 2     // Search is complete, and no key was found
#define SEARCH_STATE_NOT_FOUND 3    // Search is currently traversing the list

struct SkipListSearch *newSkipListSearch(struct SkipList *parent)
{
    struct SkipListSearch *search = malloc(sizeof *search);
    search->parent = parent;
    search->update = malloc(parent->maxLevels * sizeof (struct SLNode));
    search->node = NULL;
    search->state = SEARCH_STATE_NONE;
    
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
    if (x->next[i-1] == NULL) {
        search->state = SEARCH_STATE_NOT_FOUND;
    } else {
        search->state = SEARCH_STATE_FOUND;
        search->node = search->update[0];
    }
    return search->state = SEARCH_STATE_FOUND;
}

int searchMatchedExactString(struct SkipListSearch *search, char *keyString)
{
    if(search->state != SEARCH_STATE_FOUND) return 0;
    if(search->node == NULL) return 0;

    return strcmp(search->node->keyString, keyString) == 0;
}

char *getMatchedKeyString(struct SkipListSearch *search)
{
    if(search->state != SEARCH_STATE_FOUND && search->state != SEARCH_STATE_TRAVERSE) return NULL;
    if(search->node == NULL) return NULL;
    
    return search->node->keyString;
}

void *getMatchedValue(struct SkipListSearch *search)
{
    if(search->state != SEARCH_STATE_FOUND && search->state != SEARCH_STATE_TRAVERSE) return NULL;
    if(search->node == NULL) return NULL;

    return search->node->value;
}

int setMatchedValue(struct SkipListSearch *search, void *value)
{
    if(search->state != SEARCH_STATE_FOUND) return 0;
    if(search->node == NULL) return 0;
    
    search->node->value = value;
    return 1;
}

int advanceSearchNode(struct SkipListSearch *search)
{
    if(search->state != SEARCH_STATE_FOUND && search->state != SEARCH_STATE_TRAVERSE) return 0;
    if(search->node == NULL) return 0;
    search->node = search->node->next[0];
    if(search->node == NULL) {
        search->state = SEARCH_STATE_NONE;
        return 0;
    } else {
        search->state = SEARCH_STATE_TRAVERSE;
        return 1;
    }
}

// Generic insert for all types
int insertBeforePossibleMatch(struct SkipListSearch *search, struct SLNode *newNode, int level)
{
    struct SkipList *list = search->parent;
    if(search->state != SEARCH_STATE_FOUND && search->state != SEARCH_STATE_NOT_FOUND) return 0;
    search->state = SEARCH_STATE_NONE;
    search->node = NULL;
    
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
    if(search->state != SEARCH_STATE_FOUND && search->state != SEARCH_STATE_NOT_FOUND) return 0;

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
    if(search->state != SEARCH_STATE_FOUND) return 0;
    search->state = SEARCH_STATE_NONE;
    search->node = NULL;
    
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