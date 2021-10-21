#ifndef SYMBOL_TABLE_H
#define SYMBOL_TABLE_H

#include <iostream>
#include <cstdio>
#include <string>
#include <deque>
using namespace std;

class SymbolInfo {
    string name;
    string type;
    int size;
    SymbolInfo* next;
    bool func_defined;
public:
    deque<string> *paramList;  ///first one is set as return type

    SymbolInfo(string name, string type, int sizeOrNum = -1, deque<string> *parameters = NULL, bool function_defined = false, SymbolInfo *nextSymbol = NULL) {
        this->name = name;
        this->type = type;
        size = sizeOrNum;
        paramList = new deque<string>;
        if(parameters != NULL) {
            for(deque<string>::iterator it = parameters->begin(); it != parameters->end(); it++) {
                paramList->push_back(*it);
            }
        }
        func_defined = function_defined;
        next = nextSymbol;
    }

    string getName() { return name; }
    string getType() { return type; }
    int getSize() { return size; }
    bool functionDefined() { return func_defined; }
    SymbolInfo* getNext() { return next; }

    void setName(string input) { name = input; }
    void setType(string input) { type = input; }
    void setNext(SymbolInfo* nextPtr) { next = nextPtr; }
    void setFunctionDefined(bool func_def) { func_defined = func_def; }

    void clear() {
        name = "";
        type = "";
        size = -1;
        paramList->clear();
        next = NULL;
    }

    ~SymbolInfo() {
        paramList->clear();
        delete paramList;
    }

};

static int tableCount = 0;

class ScopeTable {
    SymbolInfo** table;
    ScopeTable* parent;
    int size;
    int scopeId;
    int prime;

    class Location {
        friend class ScopeTable;
        int hashNo, chainSl;
        SymbolInfo *now, *prev;
        Location(int hashIndex, int chainIndex, SymbolInfo* now, SymbolInfo* previous) {
            hashNo = hashIndex;
            chainSl = chainIndex;
            this->now = now;
            prev = previous;
        }
    };

    int hashValue(string str) {
        long long int value = 0;
        long long int adder;
        long long int multiplier = 1;
        for(int i = 0; i < str.length(); i++) {
            adder = str[i] + 128;  ///0~255
            value += (int)adder * multiplier;
            value %= prime;

            multiplier *= 52;
            multiplier %= prime;
        }
        return value % size;
    }

    Location locate(string input) {
        int hashNo = hashValue(input);
        int index = 0;
        SymbolInfo* prev = NULL;
        SymbolInfo* now = table[hashNo];
        if(now == NULL) {
            return Location(hashNo, index, now, prev);
        }
        while(now->getNext() != NULL && now->getName() != input) {
            prev = now;
            now = now->getNext();
            index++;
        }
        return Location(hashNo, index, now, prev);
    }

public:
    ScopeTable(int tableSize, ScopeTable* parentScope = NULL, int hashPrime = 3479249) {
        size = tableSize;
        table = new SymbolInfo*[tableSize];
        for(int i = 0; i < tableSize; i++)
            table[i] = NULL;

        parent = parentScope;
        scopeId = ++tableCount;
        if(parentScope == NULL) {
            if(scopeId != 1)
                cout << "CODEBUG: ScopeTable::tableCount and ScopeTable::scopeId may not be working correctly." << endl << endl;
        }
        //cout << endl << " New ScopeTable with id " << scopeId << " created" << endl << endl;

        prime = hashPrime;
    }

    ScopeTable* getParentScope() {
        return parent;
    }

    int getScopeId() {
        return scopeId;
    }

    bool insert(string name, string type, int sizeOrNum = -1, deque<string> *parameters = NULL, bool function_defined = false) {
        Location look = locate(name);
        if(look.now == NULL) {
            SymbolInfo* entry = new SymbolInfo(name, type, sizeOrNum, parameters, function_defined);
            table[look.hashNo] = entry;
            //cout << endl << " Inserted in ScopeTable# " << scopeId << " at position " << look.hashNo << ", 0" << endl << endl;
            //print(NULL, true);
            return true;
        }
        else if(look.now->getName() != name) {
            SymbolInfo* entry = new SymbolInfo(name, type, sizeOrNum, parameters, function_defined, look.now->getNext());
            look.now->setNext(entry);
            //cout << endl << " Inserted in ScopeTable# " << scopeId << " at position " << look.hashNo << ", " << look.chainSl+1 << endl << endl;
            //print(NULL, true);
            return true;
        }
        else {
            //cout << endl << " <" << name << "," << type << "> already exists in current ScopeTable" << endl << endl;
            //print(NULL, true);
            return false;
        }
    }

    SymbolInfo* lookUp(string input) {
        Location look = locate(input);
        if(look.now == NULL || look.now->getName() != input) {
            return NULL;
        }
        else {
            //cout << endl << " Found in ScopeTable# " << scopeId << " at position " << look.hashNo << ", " << look.chainSl << endl << endl;
            return look.now;
        }
    }

    bool deletes(string input) {
        Location look = locate(input);
        if(look.now == NULL || look.now->getName() != input) {
            //cout << endl <<  " Not found" << endl << endl;
            //cout << input << " not found" << endl <<endl;
            //print(NULL, true);
            return false;
        }
        else {
            //cout << endl << " Found in ScopeTable# " << scopeId << " at position " << look.hashNo << ", " << look.chainSl << endl << endl;
            if(look.prev == NULL) {
                table[look.hashNo] = look.now->getNext();
                delete look.now;
            }
            else {
                look.prev->setNext(look.now->getNext());
                delete look.now;
            }
            //cout << "Deleted entry at " << look.hashNo << ", " << look.chainSl << " from current ScopeTable" << endl << endl;
            //print(NULL, true);
            return true;
        }
    }

    void getAllVarName(deque<string> *varList) {  ///excludes function and array
        if(varList == NULL) {
            cout << "Error in ScopeTable::getAllVarName(...) : No varList provided." << endl;
            return;
        }
        else if(varList->size() > 0) {
            cout << "Warning in ScopeTable::getAllVarName(...) : Non-empty varList cleared." << endl;
            varList->clear();
        }
        SymbolInfo *now;
        for(int i = 0; i < size; i++) {
            now = table[i];
            while(now != NULL) {
                if(now->getType() != "FUNCTION" && now->getSize() < 0) {
                    varList->push_back(now->getName());
                }
                now = now->getNext();
            }
        }
    }

    void print(FILE *file, bool console = false) {
        fprintf(file,"\n ScopeTable # %d\n", scopeId);
        for(int i = 0; i < size; i++) {
            bool idPrint = false;
            SymbolInfo* now = table[i];
            SymbolInfo* temp;
            while(now != NULL) {
                if(!idPrint) {
                    if(console)
                        printf("\n %d -->  ", i);
                    else
                        fprintf(file,"\n %d -->  ", i);
                    idPrint = true;
                }
                if(console)
                    printf("< %s : %s ", now->getName().c_str(),now->getType().c_str());
                else
                    fprintf(file,"< %s : %s ", now->getName().c_str(),now->getType().c_str());
                if(now->getSize() >= 0 ) {
                    if(console)
                        printf(": %d ", now->getSize());
                    else
                        fprintf(file, ": %d ", now->getSize());
                }
                if(!now->paramList->empty()) {
                    if(console)
                        printf("[ (%s) ", now->paramList->begin()->c_str());
                    else
                        fprintf(file, "[ (%s) ", now->paramList->begin()->c_str());
                    for(deque<string>::iterator it = now->paramList->begin() + 1; it != now->paramList->end(); it++) {
                        if(console)
                            printf("%s ", it->c_str());
                        else
                            fprintf(file, "%s ", it->c_str());
                    }
                    if(console)
                        printf("] ");
                    else
                        fprintf(file, "] ");
                }
                if(now->getType().compare("FUNCTION") == 0) {
                    if(now->functionDefined()) {
                        if(console)
                            printf("(DEFINED) ");
                        else
                            fprintf(file,"(DEFINED) ");
                    }
                }
                if(console)
                    printf("> ");
                else
                    fprintf(file,"> ");
                now = now->getNext();
            }
            if(idPrint) {
            if(console)
                printf("\n");
            else
                fprintf(file, "\n");
            }
        }
        if(console)
            printf("\n");
        else
            fprintf(file, "\n");
    }

    ~ScopeTable() {
        for(int i = 0; i < size; i++) {
            SymbolInfo* now = table[i];
            SymbolInfo* temp;
            while(now != NULL) {
                temp = now->getNext();
                delete now;
                now = temp;
            }
        }
        if(parent != NULL) {
            //cout << endl << " ScopeTable with id " << scopeId << " removed" << endl << endl;
        }
    }
};

class SymbolTable {
    ScopeTable *currentScope;
    int size;  ///default

public:
    SymbolTable(int bucketSize) {
        size = bucketSize;
        currentScope = new ScopeTable(size);
    }

    void enterScope() {
        currentScope = new ScopeTable(size, currentScope);
    }
    void exitScope() {
        ScopeTable *parent = currentScope->getParentScope();
        if(parent == NULL) {
            cout << endl << " ERROR: Cannot exit scope." << endl << endl;
            return;
        }
        delete currentScope;
        currentScope = parent;
    }
    void decreaseTableCount() {  ///to get rid of spare ScopeTable constructions
        tableCount--;
    }
    int getCurrentScopeId() {
        return currentScope->getScopeId();
    }
    bool insert(string name, string type, int sizeOrNum = -1, deque<string> *parameters = NULL, bool function_defined = false) {
        return currentScope->insert(name, type, sizeOrNum, parameters, function_defined);
    }
    bool remove(string input) {
        return currentScope->deletes(input);
    }
    SymbolInfo* lookUp(string input) {
        SymbolInfo *look = NULL;
        ScopeTable *nowScope = currentScope;
        while(look == NULL && nowScope != NULL) {
            look = nowScope->lookUp(input);
            nowScope = nowScope->getParentScope();
        }
        //if(look == NULL)  cout << endl << " Not found" << endl << endl;

        return look;
    }
    int lookUpScope(string input) {
        int scopeId;
        SymbolInfo *look = NULL;
        ScopeTable *nowScope = currentScope;
        while(look == NULL && nowScope != NULL) {
            look = nowScope->lookUp(input);
            scopeId = nowScope->getScopeId();
            nowScope = nowScope->getParentScope();
        }
        //if(look == NULL)  cout << endl << " Not found" << endl << endl;
        if(look == NULL) scopeId = 0;

        return scopeId;
    }

    void getAllVarNameCS(deque<string> *varList) {    ///excludes function and array; [CS] = Current Scope
        currentScope->getAllVarName(varList);
    }

    void printCurrentScopeTable(FILE* file, bool console = false) {
        currentScope->print(file, console);
    }
    void printAllScopeTable(FILE* file, bool console = false) {
        ScopeTable *nowScope = currentScope;
        while(nowScope != NULL) {
            nowScope->print(file, console);
            nowScope = nowScope->getParentScope();
        }
    }
};

#endif // SYMBOL_TABLE_H
