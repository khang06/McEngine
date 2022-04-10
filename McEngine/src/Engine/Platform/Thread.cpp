//================ Copyright (c) 2020, PG, All rights reserved. =================//
//
// Purpose:		thread wrapper
//
// $NoKeywords: $thread $os
//===============================================================================//

#include "Thread.h"
#include "ConVar.h"
#include "Engine.h"

#include "HorizonThread.h"

#ifdef MCENGINE_FEATURE_MULTITHREADING

#ifdef MCENGINE_FEATURE_PTHREADS

#include <pthread.h>

// pthread implementation of Thread
class PosixThread : public BaseThread
{
public:
	PosixThread(McThread::START_ROUTINE start_routine, void *arg) : BaseThread()
	{
		m_thread = 0;

		const int ret = pthread_create(&m_thread, NULL, start_routine, arg);
		m_bReady = (ret == 0);

		if (ret != 0)
			debugLog("PosixThread Error: pthread_create() returned %i!\n", ret);
	}

	virtual ~PosixThread()
	{
		if (!m_bReady) return;

		m_bReady = false;

		pthread_join(m_thread, NULL);

		m_thread = 0;
	}

	bool isReady()
	{
		return m_bReady;
	}

private:
	pthread_t m_thread;

	bool m_bReady;
};

#elif defined(_MSC_VER)

#include <Windows.h>

class WindowsThread : public BaseThread {
public:
	WindowsThread(McThread::START_ROUTINE start_routine, void* arg) : BaseThread() {
		m_thread = CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)start_routine, arg, 0, NULL);
		m_bReady = (m_thread != NULL);

		if (m_thread == NULL)
			debugLog("WindowsThread Error: CreateThread() failed! GetLastError %i\n", GetLastError());
	}

	virtual ~WindowsThread() {
		if (!m_bReady)
			return;
		m_bReady = false;

		WaitForSingleObject(m_thread, INFINITE);

		m_thread = NULL;
	}

	bool isReady() {
		return m_bReady;
	}

private:
	HANDLE m_thread;
	bool m_bReady;
};

#endif

#endif

ConVar debug_thread("debug_thread", false);

ConVar *McThread::debug = &debug_thread;

McThread::McThread(START_ROUTINE start_routine, void *arg)
{
	m_baseThread = NULL;

#ifdef MCENGINE_FEATURE_MULTITHREADING

#ifdef MCENGINE_FEATURE_PTHREADS

	m_baseThread = new PosixThread(start_routine, arg);

#elif defined(__SWITCH__)

	m_baseThread = new HorizonThread(start_routine, arg);

#elif defined(_MSC_VER)

	m_baseThread = new WindowsThread(start_routine, arg);

#else
#error Missing Thread implementation for OS!
#endif

#endif
}

McThread::~McThread()
{
	SAFE_DELETE(m_baseThread);
}

bool McThread::isReady()
{
	return (m_baseThread != NULL && m_baseThread->isReady());
}
