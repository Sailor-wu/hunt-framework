/*
 * Copyright 2002-2014 the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

module hunt.framework.messaging.support.MessageHandlingRunnable;


import hunt.framework.messaging.Message;
import hunt.framework.messaging.MessageHandler;

import hunt.lang.common;

/**
 * Extension of the {@link Runnable} interface with methods to obtain the
 * {@link MessageHandler} and {@link Message} to be handled.
 *
 * @author Rossen Stoyanchev
 * @since 4.1.1
 */
interface MessageHandlingRunnable(T) : Runnable {

	/**
	 * Return the Message that will be handled.
	 */
	Message!T getMessage();

	/**
	 * Return the MessageHandler that will be used to handle the message.
	 */
	MessageHandler getMessageHandler();

}