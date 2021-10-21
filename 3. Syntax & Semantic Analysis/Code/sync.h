#ifndef SYNC_H
#define SYNC_H

#include<string>
#include <deque>
#include "symbol_table.h"
using namespace std;

enum class functionState {
    defNdeclare, mulDeclare, mulDef, manyLessArgs, unmatchedArgs, define
};

class Sync {
public:
    string output;

    Sync(const string &out) {
        output = out;
    }

    ///type for detecting compatibility of operators
    string type = "";

    ///variable declaration
    deque<string> *var_list = new deque<string>;
    deque<int> *var_size_list = new deque<int>;
    deque<string> *varExists = new deque<string>;
    string var_type = "";

    void startVarDeclare() {
        var_list->clear();
        var_size_list->clear();
        varExists->clear();
        var_type = "";
    }
    void addVar(string var_name, int var_size = -1) {
        var_list->push_back(var_name);
        var_size_list->push_back(var_size);
    }
    bool flushVarList(SymbolTable *table) {     ///must set var_type
                                                ///returns success value
        varExists->clear();
        string name;
        int size;
        bool void_type = false;
        if(var_type.compare("VOID") == 0) {
            void_type = true;
            var_list->clear();
            var_size_list->clear();
            var_type = "";
        }
        else {
            while(!var_list->empty()) {
                name = var_list->front();
                var_list->pop_front();
                size = var_size_list->front();
                var_size_list->pop_front();
                if(!table->insert(name,var_type,size)) {
                    varExists->push_back(name);
                }
            }
            var_type = "";
        }
        return varExists->empty() && (!void_type);
    }

    ///function declaration
    deque<string> *type_list = new deque<string>;
    deque<string> *name_list = new deque<string>;
    deque<string> *paramExists = new deque<string>;
    int param_list_size = 0;  ///excludes return type
    bool unnamed_parameter = false;

    void startFuncDeclare() {
        type_list->clear();
        name_list->clear();
        paramExists->clear();
        param_list_size = 0;
        unnamed_parameter = false;
    }
    void addParam(string type, string name) {
        type_list->push_back(type);
        name_list->push_back(name);
        param_list_size++;
    }
private:
    bool declareFuncBasic(string retType, string funcName, bool func_defined, SymbolTable *table) {  ///returns success value of insertion
        paramExists->clear();
        string name, type;
        bool insert = false;
        table->enterScope();
        for(deque<string>::iterator it = name_list->begin(); it != name_list->end(); it++)  {
            name = *it;
            if(name.compare("") != 0) {
                if(!table->insert(name, "CHECK IF REPEATED")) {
                    paramExists->push_back(name);
                }
            }
            else {
                unnamed_parameter = true;
            }
        }
        table->exitScope();
        table->decreaseTableCount();
        type_list->push_front(retType);  ///CODEMOD: return type pushed at front.
        if(table->insert(funcName, "FUNCTION", param_list_size, type_list, func_defined)) {
            insert = true;
        }
        return insert;
    }
public:
    bool declareFunc(string retType, string funcName, SymbolTable *table) {  ///returns success value
        bool insert = declareFuncBasic(retType, funcName, false, table);
        type_list->clear();
        name_list->clear();
        return insert;
    }

    ///function definition
    functionState defineFuncTop(string retType, string funcName, SymbolTable *table) {
        SymbolInfo *look = table->lookUp(funcName);
        if(look == NULL) {
            declareFuncBasic(retType, funcName, true, table);
            return functionState::defNdeclare;
        }
        else if(look->getType().compare("FUNCTION") != 0) {
            return functionState::mulDeclare;
        }
        else {
            if(look->functionDefined()) {
                return functionState::mulDef;
            }
            else if(look->getSize() != param_list_size) {
                return functionState::manyLessArgs;
            }
            else {
                bool match = true;
                for(deque<string>::iterator it = look->paramList->begin(), jt = type_list->begin();
                            it != look->paramList->end(), jt != type_list->end(); it++, jt++) {
                    if(it->compare(*jt) != 0) {
                        match = false;
                        break;
                    }
                }
                if(!match) {
                    return functionState::unmatchedArgs;
                }
                else {
                    return functionState::define;
                }
            }
            look->setFunctionDefined(true);
        }
    }

    void defineFuncBody(SymbolTable *table) {
        ///WARNING: remember that type_list has return type pushed at front
        //type_list->pop_front();
        string type, name;
        while(!type_list->empty()) {
            //printf("%s %s", type_list->front().c_str(),name_list->front().c_str());
            type = type_list->front();
            type_list->pop_front();
            name = name_list->front();
            name_list->pop_front();
            if(name.compare("") != 0) {
                table->insert(name, type);
            }
        }

    }

    ~Sync() {
        var_list->clear();
        delete var_list;
        var_size_list->clear();
        delete var_size_list;
        varExists->clear();
        delete varExists;
    }

};

#endif // SYNC_H
