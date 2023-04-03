#ifndef SIMPLUSPLUS_HANDLE_H_INCLUDED
#define SIMPLUSPLUS_HANDLE_H_INCLUDED

#include <string>
#include <boost/format.hpp>
#include <boost/regex.hpp>
#include <boost/lexical_cast.hpp>

#include <simPlusPlus/Lib.h>

namespace sim
{
    /*! \brief A tool for converting pointers to strings and vice versa.
     *
     * Usage: specialize the Handle<T>::tag() method for your class, e.g.:
     *
     * template<> std::string Handle<OcTree>::tag() { return "octomap.OcTree"; }
     *
     * Note: tag must not contain ":"
     */
    template<typename T>
    struct Handle
    {
        static std::string str(T *t)
        {
            boost::format fmt("%s:%lld:%d");
            return (fmt % validatedTag() % reinterpret_cast<long long int>(t) % crcPtr(t)).str();
        }

        static T * obj(std::string h)
        {
            boost::cmatch m;
            boost::regex re("([^:]+):([^:]+):([^:]+)");
            if(boost::regex_match(h.c_str(), m, re) && m[1] == validatedTag())
            {
                T *t = reinterpret_cast<T*>(boost::lexical_cast<long long int>(m[2]));
                int crc = boost::lexical_cast<int>(m[3]);
                if(crc == crcPtr(t)) return t;
            }
            return nullptr;
        }

    private:
        static std::string tag()
        {
            return "ptr";
        }

        static std::string validatedTag()
        {
            auto t = tag();
            if(t.find(':') != std::string::npos)
                throw std::runtime_error("Handle's tag cannot contain the ':' character (this error is for developers)");
            return t;
        }

        static int crcPtr(T *t)
        {
            auto x = reinterpret_cast<long long int>(t);
            x = x ^ (x >> 32);
            x = x ^ (x >> 16);
            x = x ^ (x >> 8);
            x = x ^ (x >> 4);
            x = x & 0x000000000000000F;
            x = x ^ 0x0000000000000008;
            return int(x);
        }
    };

    template<typename T>
    struct Handles
    {
        std::string add(T *t, int scriptID)
        {
            int sceneID = getSceneID(scriptID);
            handlesf[sceneID][scriptID].insert(t);
            handlesr[t][sceneID] = scriptID;
            return Handle<T>::str(t);
        }

        T * remove(T *t)
        {
            auto it = handlesr.find(t);
            if(it == handlesr.end()) return t;
            for(const auto &m : it->second)
            {
                int sceneID = m.first;
                int scriptID = m.second;
                auto it1 = handlesf.find(sceneID);
                if(it1 == handlesf.end()) continue;
                auto it2 = it1->second.find(scriptID);
                if(it2 == it1->second.end()) continue;
                it2->second.erase(t);
            }
            handlesr.erase(it);
            return t;
        }

        T * get(std::string h) const
        {
            T *ret = Handle<T>::obj(h);
            if(!ret)
                throw std::runtime_error("invalid object handle");
            if(handlesr.find(ret) == handlesr.end())
                throw std::runtime_error("non-existent object handle");
            return ret;
        }

        std::set<T*> find(int scriptID) const
        {
            int sceneID = getSceneID(scriptID);
            auto it = handlesf.find(sceneID);
            if(it == handlesf.end()) return {};
            auto it2 = it->second.find(scriptID);
            if(it2 == it->second.end()) return {};
            return it2->second;
        }

        std::set<T*> findBySceneOfScript(int scriptID) const
        {
            return findByScene(getSceneID(scriptID));
        }

        std::set<T*> findByScene(int sceneID) const
        {
            auto it = handlesf.find(sceneID);
            if(it == handlesf.end()) return {};
            std::set<T*> r;
            for(const auto &x : it->second)
                for(auto t : x.second)
                    r.insert(t);
            return r;
        }

        std::set<T*> all() const
        {
            std::set<T*> r;
            for(const auto &x : handlesr)
                r.insert(x.first);
            return r;
        }

        std::set<std::string> handles() const
        {
            std::set<std::string> r;
            for(const auto &x : handlesr)
                r.insert(Handle<T>::str(x.first));
            return r;
        }

    private:
        static int getSceneID(int scriptID)
        {
            int scriptType, objectHandle;
            sim::getScriptProperty(scriptID, &scriptType, &objectHandle);
            if(0
                    || scriptType == sim_scripttype_mainscript
                    || scriptType == sim_scripttype_childscript
                    || scriptType == sim_scripttype_customizationscript
            )
                return sim::getInt32Parameter(sim_intparam_scene_unique_id);
            else
                return -1;
        }

        // Tables of created objects (for methods: add, remove, find)

        // sceneID -> (scriptID -> [objects])
        std::map<int, std::map<int, std::set<T*>>> handlesf;

        // object -> (sceneID -> scriptID)
        std::map<T*, std::map<int, int>> handlesr;
    };
}

#endif // SIMPLUSPLUS_HANDLE_H_INCLUDED
