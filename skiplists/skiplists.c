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

// maxlevels is the max depth of this skiplist
struct C_SkipListNode *newSkipListNode(int maxLevels, int level)
{
    struct C_SkipListNode *node = malloc(sizeof *node);
    node->keyString = NULL;
    node->value = NULL;
    node -> level = level;
    node->next = malloc(maxLevels * sizeof node);

    int i;
    for(i = 0; i < maxLevels; i++)
        node->next[i] = NULL;

    return node;
}

void destroySkipListNode(struct C_SkipListNode *node)
{
    if(node) {
        if(node -> keyString) free(node->keyString);
        free(node->next);
        free(node);
    }
}

struct C_SkipList *newSkipList(int maxLevels, int type)
{
    struct C_SkipList *list = malloc(sizeof *list);
    list->head = newSkipListNode(maxLevels, 0);
    list->maxLevels = maxLevels;
    list->level = 1;
    list->type = type;
    return list;
}

void destroySkipList(struct C_SkipList *list)
{
    if(list) {
        while(list->head) {
            struct C_SkipListNode *next = list->head->next[0];
            destroySkipListNode(list->head);
            list->head = next;
        }
        free(list);
    }
}


struct C_SkipListSearch *newSkipListSearch(struct C_SkipList *parent)
{
    struct C_SkipListSearch *search = malloc(sizeof *search);
    if(!search) return NULL;
    search->update = malloc(parent->maxLevels * sizeof (struct C_SkipListNode));
    if(!search->update) { free(search); return NULL; }
    search->parent = parent;
    search->node = NULL;
    search->state = SEARCH_STATE_NONE;
    
    int i;
    for(i = 0; i < parent->maxLevels; i++)
        search->update[i] = NULL;

    return search;
}

void destroySkipListSearch(struct C_SkipListSearch *search)
{
    if(search) {
        free(search->update);
        free(search);
    }
}

// Shortcut search set up to traverse the whole list
void traverseSkipList(struct C_SkipListSearch *search)
{
    if(search->parent->head) {
        search->node = search->parent->head->next[0];
    } else {
        search->node = NULL;
    }
    search->state = search->node ? SEARCH_STATE_TRAVERSE : SEARCH_STATE_NONE;
}

int searchSkipListString(struct C_SkipListSearch *search, const char *keyString)
{
    struct C_SkipList *list = search->parent;
    struct C_SkipListNode *x = list->head;
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

int searchMatchedExactString(struct C_SkipListSearch *search, const char *keyString)
{
    if(search->state != SEARCH_STATE_FOUND) return 0;
    if(search->node == NULL) return 0;

    return strcmp(search->node->keyString, keyString) == 0;
}

const char *getMatchedKeyString(struct C_SkipListSearch *search)
{
    if(search->state != SEARCH_STATE_FOUND && search->state != SEARCH_STATE_TRAVERSE) return NULL;
    if(search->node == NULL) return NULL;
    
    return search->node->keyString;
}

void *getMatchedValue(struct C_SkipListSearch *search)
{
    if(search->state != SEARCH_STATE_FOUND && search->state != SEARCH_STATE_TRAVERSE) return NULL;
    if(search->node == NULL) return NULL;

    return search->node->value;
}

int setMatchedValue(struct C_SkipListSearch *search, void *value)
{
    if(search->state != SEARCH_STATE_FOUND) return 0;
    if(search->node == NULL) return 0;
    
    search->node->value = value;
    return 1;
}

int advanceSearchNode(struct C_SkipListSearch *search)
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
int insertBeforePossibleMatch(struct C_SkipListSearch *search, struct C_SkipListNode *newNode, int level)
{
    struct C_SkipList *list = search->parent;
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

int searchCanInsert(struct C_SkipListSearch *search)
{
    return search->state == SEARCH_STATE_FOUND || search->state == SEARCH_STATE_NOT_FOUND;
}

// Specific insert for string
int insertBeforePossibleMatchString(struct C_SkipListSearch *search, const char *keyString, void *value)
{
    struct C_SkipList *list = search->parent;
    if(search->state != SEARCH_STATE_FOUND && search->state != SEARCH_STATE_NOT_FOUND) return 0;

    // Pick a random level for the new node
    int level = randomLevel(list->maxLevels);

    // Create the new node
    struct C_SkipListNode *newNode = newSkipListNode(list->maxLevels, level);
    strcpy(newNode->keyString = malloc(strlen(keyString) + 1), keyString);
    newNode -> value = value;
    
    // Call the general routine for the tricky stuff
    if (!insertBeforePossibleMatch(search, newNode, level)) { // can't happen
        destroySkipListNode(newNode);
        return 0;
    }
    return 1;
}

int deleteMatchedNode(struct C_SkipListSearch *search)
{
    struct C_SkipList *list = search->parent;
    if(search->state != SEARCH_STATE_FOUND) return 0;
    search->state = SEARCH_STATE_NONE;
    search->node = NULL;
    
    struct C_SkipListNode *x = search->update[0];
    
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
    destroySkipListNode(x);
    
    return 1;
}