#include <iostream>
#include <sstream>
#include <fstream>
#include <vector>
#include <set>
#include <algorithm>


using namespace std;
set <int> FINAL_STATES; // Store final states
/**
 * @param {vector<string>*} ptr 
    a pointer to the string vector
 * 
 * @description
 * The function outputs the element of the vector ending with newline
 */
void output(vector<string> *ptr) {
    for (int i=0; i< ptr->size(); ++i) {
        cout << (*ptr)[i] << endl;
    }
}

/**
 * @param {vector<set<int> >*} ptr 
    a pointer to the vecotr which contains all transition sets
 * @param {int} alphabet
    the size of alphabet
 *
 * @description
 * The function outputs transion sets of all states
 */
void outputTrans(vector<set<int> > *ptr, int alphabet) {
    for (int i=0; i< ptr->size(); ++i) {
        //printf("{");
        cout << "{";
        set<int>::iterator it = (*ptr)[i].begin();
        while (!(*ptr)[i].empty()) {
            //printf("%d,",*it);
            cout << *it;
            ++it;
            if (it ==(*ptr)[i].end()) {
                //printf("\b");
                break;
            } else {
                cout << ',';
            }
        }
        if ((i+1)%alphabet == 0 && i != 0)
            //printf("}\n");
            cout << "}\n";
        else
            //printf("} ");
            cout << "} ";
    }
}

/**
 * @param {string*} str 
    a pointer to a transition set
 * @param {set<int>*} ptr
    a pointer to a temperary set which can store current states in the str as integer
 *
 * @description
 * The function get all states in the transition set and store them in a set
 * A transition set must be formatted as "{state1,state2..stateN}"
 */
void extract_states(string *str, set<int> *ptr) {
    if (!ptr->empty())
        ptr->clear();
    stringstream ss(*str);
    int f,s;
    while ((f = ss.get())!='}') {
        if (f == '{')
            continue;
        if (f != ',') {
            if (ss.peek() != ',' && ss.peek() != '}'){
                s = ss.get();
                ptr->insert((f-48)*10+s-48);
            } else{
                ptr->insert(f-48);
            }
        }
    }
}
/**
 * @param {vector<set<int> >*} ptr 
    a pointer to the vecotr which contains all transition sets with epsilon moves
 * @param {int} max_states
    the total number of states
 * @param {int} alphabet
    the number of alphabet size
 *
 * @description
 * Use {curr_trans} to find the index of the transition set of epsilon moves for a state
 * Use {change} to check if there are new states added to a transition set after following a epsilon move
 * Use {updated} to track the index of a transition set after adding new states
 * Use {it} as the iterator of a epsilon transitiosn set
 *
 * The function remove all epsilon transitios in the transitions sets
 * The function will start removing epsilon moves at first state and keeping looping until there is no new transitions added. 
 */
void epsilonremoval(vector<set<int> > *ptr, int alphabet, int max_state) {
    int curr_trans, change;
    int state = 0;
    set<int> updated;
    set<int>::iterator it;

    while(true) {
        if (state == max_state && updated.empty()) {
            state = 0;
            break;
        }
        if (state == max_state) {
            state = 0;
        }
        curr_trans = state*alphabet;
        if (!(*ptr)[curr_trans].empty()) {
            it = (*ptr)[curr_trans].begin();
            while (it != (*ptr)[curr_trans].end()) {
                if (FINAL_STATES.find(*it) != FINAL_STATES.end())
                    FINAL_STATES.insert(state);

                // Add new trans to the current state
                for (int i=1; i< alphabet; ++i) {
                    change = (*ptr)[curr_trans+i].size();
                    (*ptr)[curr_trans+i].insert((*ptr)[(*it)*alphabet+i].begin(), (*ptr)[(*it)*alphabet+i].end());
                    if (change !=(*ptr)[curr_trans+i].size()) {
                        updated.insert(curr_trans+i);
                    } else {
                        updated.erase(curr_trans+i);
                    }
                }
                ++it;
            }
        }
        ++state;
    }

    // Remove all epsilon transitions
    while(true) {
        if (state == max_state) {
            break;
        }
        (*ptr)[state*alphabet].clear();
        ++state;
    }

}

 /**
 * @param {char*[]} argv 
    A array store command line arguments
 * @description
 * Main function
 *
 * 1. Read an NFA description file
    Stroe all transitions into a vector following the reading order
 * 2. Do epsilon remove
 * 3. Ouptput results
 */
int main(int argc, char *argv[]) {
    const char* STATESLINE ="Number of states: ";
    const char* ALPHABETLINE = "Alphabet size: ";
    const char* FINALSLINE ="Accepting states: ";

    ifstream file(argv[1]);
    string line,temp;
    vector<set<int> > transitions;
    set<int> temp_trans;
    int states =-3;
    int acState;

    while (getline(file, line)) {
        if (states == -1) {
            temp = (line.substr(18));
            stringstream inss(temp);
            while (inss >> acState) {
                FINAL_STATES.insert(acState);
            }
        } else if (states > -1) {
            stringstream inss(line);
            while (inss >> temp) {
                extract_states(&temp, &temp_trans);
                transitions.push_back(temp_trans);
            }
        }
        ++states;
    }
    file.close();

    epsilonremoval(&transitions, (transitions.size()/states), states);

    cout << STATESLINE << states << '\n' << ALPHABETLINE << (transitions.size()/states)-1 <<'\n' <<FINALSLINE ;
    set<int>::iterator fit = FINAL_STATES.begin();
    while (!FINAL_STATES.empty()) {
        cout << (*fit);
        ++fit;
        if (fit != FINAL_STATES.end()) {
            cout << ' ';
        } else {
            break;
        }
    }
    printf("\n");
    outputTrans(&transitions, (transitions.size()/states));

    return 0;
}
