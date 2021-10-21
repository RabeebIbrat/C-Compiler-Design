#include <iostream>
#include <string>
using namespace std;

class SymbolInfo {
    string name;
    string type;
    SymbolInfo* next;
public:
    SymbolInfo(string name, string type) {
        this->name = name;
        this->type = type;
        next = NULL;
    }
    SymbolInfo(string name, string type, SymbolInfo* nextSymbol) {
        this->name = name;
        this->type = type;
        next = nextSymbol;
    }
    string getName() { return name; }
    string getType() { return type; }
    SymbolInfo* getNext() { return next; }

    void setName(string input) { name = input; }
    void setType(string input) { type = input; }
    void setNext(SymbolInfo* nextPtr) { next = nextPtr; }

};

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
        if(parentScope == NULL)
            scopeId = 1;
        else {
            scopeId = parentScope->scopeId + 1;
            cout << endl << " New ScopeTable with id " << scopeId << " created" << endl << endl;
        }

        prime = hashPrime;
    }

    ScopeTable* getParentScope() { return parent; }

    bool insert(string input, string type) {
        Location look = locate(input);
        if(look.now == NULL) {
            SymbolInfo* entry = new SymbolInfo(input, type);
            table[look.hashNo] = entry;
            cout << endl << " Inserted in ScopeTable# " << scopeId << " at position " << look.hashNo << ", 0" << endl << endl;
            return true;
        }
        else if(look.now->getName() != input) {
            SymbolInfo* entry = new SymbolInfo(input, type, look.now->getNext());
            look.now->setNext(entry);
            cout << endl << " Inserted in ScopeTable# " << scopeId << " at position " << look.hashNo << ", " << look.chainSl+1 << endl << endl;
            return true;
        }
        else {
            cout << endl << " <" << input << "," << type << "> already exists in current ScopeTable" << endl << endl;
            return false;
        }
    }

    SymbolInfo* lookUp(string input) {
        Location look = locate(input);
        if(look.now == NULL || look.now->getName() != input) {
            return NULL;
        }
        else {
            cout << endl << " Found in ScopeTable# " << scopeId << " at position " << look.hashNo << ", " << look.chainSl << endl << endl;
            return look.now;
        }
    }

    bool deletes(string input) {
        Location look = locate(input);
        if(look.now == NULL || look.now->getName() != input) {
            cout << endl <<  " Not found" << endl << endl;
            cout << input << " not found" << endl <<endl;
            return false;
        }
        else {
            cout << endl << " Found in ScopeTable# " << scopeId << " at position " << look.hashNo << ", " << look.chainSl << endl << endl;
            if(look.prev == NULL) {
                table[look.hashNo] = look.now->getNext();
                delete look.now;
            }
            else {
                look.prev->setNext(look.now->getNext());
                delete look.now;
            }
            cout << "Deleted entry at " << look.hashNo << ", " << look.chainSl << " from current ScopeTable" << endl << endl;
            return true;
        }
    }

    void print() {
        cout << endl << " ScopeTable # " << scopeId << endl;
        for(int i = 0; i < size; i++) {
            cout << " " << i << " -->  ";
            SymbolInfo* now = table[i];
            SymbolInfo* temp;
            while(now != NULL) {
                cout << "< " << now->getName() << " : " << now->getType() << "> ";
                now = now->getNext();
            }
            cout << endl;
        }
        cout << endl;
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
            cout << endl << " ScopeTable with id " << scopeId << " removed" << endl << endl;
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
        delete currentScope;
        currentScope = parent;
    }
    bool insert(string input, string type) {
        return currentScope->insert(input, type);
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
        if(look == NULL)  cout << endl << " Not found" << endl << endl;

        return look;
    }
    void printCurrentScopeTable() {
        currentScope->print();
    }
    void printAllScopeTable() {
        ScopeTable *nowScope = currentScope;
        while(nowScope != NULL) {
            nowScope->print();
            nowScope = nowScope->getParentScope();
        }
    }
};

int main() {
    int bucketSize;
    cin >> bucketSize;
    SymbolTable table(bucketSize);

    cout << endl;
    string input,name,type;
    while(true) {
        cin >> input;
        if(input == "I") {
            cin >> name >> type;
            table.insert(name,type);
        }
        else if(input == "L") {
            cin >> name;
            table.lookUp(name);
        }
        else if(input == "D") {
            cin >> name;
            table.remove(name);
        }
        else if(input == "P") {
            cin >> input;
            if(input == "A") {
                table.printAllScopeTable();
            }
            else if(input == "C") {
                table.printCurrentScopeTable();
            }
            else {
                cout << "Invalid command sequence." << endl;
            }
        }
        else if(input == "S") {
            table.enterScope();
        }
        else if(input == "E") {
            table.exitScope();
        }
        else {
            cout << "Invalid command sequence." << endl;
        }

    }
}
