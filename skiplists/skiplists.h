//
//  skiplists.h
//  skiplists
//
//  Created by Peter da Silva on 6/11/16.
//  Copyright © 2016 Flightaware. All rights reserved.
//

#ifndef skiplists_h
#define skiplists_h

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct C_SkipListNode {
    char *keyString;
    int level;
    void *value;
    struct C_SkipListNode **next;
};

struct C_SkipList {
    struct C_SkipListNode *head;
    int maxLevels;
    int level;
    int type; // reserved
};

#define SKIPLIST_UNKNOWN 0
#define SKIPLIST_STRING 1
#define SKIPLIST_INT 2
#define SKIPLIST_DOUBLE 3

struct C_SkipListSearch {
    struct C_SkipList *parent;
    struct C_SkipListNode **update;
    struct C_SkipListNode *node;
    int state;
};

#define SEARCH_STATE_NONE 0         // Not a valid search, either new or an insert/delete operation has occurred
#define SEARCH_STATE_FOUND 1        // Search is complete, and a key (may not be exact match) was found
#define SEARCH_STATE_TRAVERSE 2     // Search is complete, and no key was found
#define SEARCH_STATE_NOT_FOUND 3    // Search is currently traversing the list

struct C_SkipList *newSkipList(int maxLevels, int type);
void destroySkipList(struct C_SkipList *list);
int searchSkipListString(struct C_SkipListSearch *search, const char *key);
int searchMatchedExactString(struct C_SkipListSearch *search, const char *keyString);
int insertBeforePossibleMatchString(struct C_SkipListSearch *search, const char *keyString, void *value);
int deleteMatchedNode(struct C_SkipListSearch *search);
char *getMatchedKeyString(struct C_SkipListSearch *search);
void *getMatchedValue(struct C_SkipListSearch *search);
int setMatchedValue(struct C_SkipListSearch *search, void *value);
int advanceSearchNode(struct C_SkipListSearch *search);
void destroySkipListSearch(struct C_SkipListSearch *search);
struct C_SkipListSearch *newSkipListSearch(struct C_SkipList *parent);
int searchCanInsert(struct C_SkipListSearch *search);

#endif /* skiplists_h */
