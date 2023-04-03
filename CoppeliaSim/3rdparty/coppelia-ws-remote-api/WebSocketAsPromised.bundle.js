require=(function(){function r(e,n,t){function o(i,f){if(!n[i]){if(!e[i]){var c="function"==typeof require&&require;if(!f&&c)return c(i,!0);if(u)return u(i,!0);var a=new Error("Cannot find module '"+i+"'");throw a.code="MODULE_NOT_FOUND",a}var p=n[i]={exports:{}};e[i][0].call(p.exports,function(r){var n=e[i][1][r];return o(n||r)},p,p.exports,r,e,n,t)}return n[i].exports}for(var u="function"==typeof require&&require,i=0;i<t.length;i++)o(t[i]);return o}return r})()({1:[function(require,module,exports){
'use strict';

var GetIntrinsic = require('get-intrinsic');

var callBind = require('./');

var $indexOf = callBind(GetIntrinsic('String.prototype.indexOf'));

module.exports = function callBoundIntrinsic(name, allowMissing) {
	var intrinsic = GetIntrinsic(name, !!allowMissing);
	if (typeof intrinsic === 'function' && $indexOf(name, '.prototype.') > -1) {
		return callBind(intrinsic);
	}
	return intrinsic;
};

},{"./":2,"get-intrinsic":26}],2:[function(require,module,exports){
'use strict';

var bind = require('function-bind');
var GetIntrinsic = require('get-intrinsic');

var $apply = GetIntrinsic('%Function.prototype.apply%');
var $call = GetIntrinsic('%Function.prototype.call%');
var $reflectApply = GetIntrinsic('%Reflect.apply%', true) || bind.call($call, $apply);

var $gOPD = GetIntrinsic('%Object.getOwnPropertyDescriptor%', true);
var $defineProperty = GetIntrinsic('%Object.defineProperty%', true);
var $max = GetIntrinsic('%Math.max%');

if ($defineProperty) {
	try {
		$defineProperty({}, 'a', { value: 1 });
	} catch (e) {
		// IE 8 has a broken defineProperty
		$defineProperty = null;
	}
}

module.exports = function callBind(originalFunction) {
	var func = $reflectApply(bind, $call, arguments);
	if ($gOPD && $defineProperty) {
		var desc = $gOPD(func, 'length');
		if (desc.configurable) {
			// original length, plus the receiver, minus any additional arguments (after the receiver)
			$defineProperty(
				func,
				'length',
				{ value: 1 + $max(0, originalFunction.length - (arguments.length - 1)) }
			);
		}
	}
	return func;
};

var applyBind = function applyBind() {
	return $reflectApply(bind, $apply, arguments);
};

if ($defineProperty) {
	$defineProperty(module.exports, 'apply', { value: applyBind });
} else {
	module.exports.apply = applyBind;
}

},{"function-bind":25,"get-intrinsic":26}],3:[function(require,module,exports){
/* chnl v1.2.0 by Vitaliy Potapov @preserve */
"use strict";function _typeof(e){return(_typeof="function"==typeof Symbol&&"symbol"==typeof Symbol.iterator?function(e){return typeof e}:function(e){return e&&"function"==typeof Symbol&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e})(e)}function _classCallCheck(e,t){if(!(e instanceof t))throw new TypeError("Cannot call a class as a function")}function _defineProperties(e,t){for(var n=0;n<t.length;n++){var r=t[n];r.enumerable=r.enumerable||!1,r.configurable=!0,"value"in r&&(r.writable=!0),Object.defineProperty(e,r.key,r)}}function _createClass(e,t,n){return t&&_defineProperties(e.prototype,t),n&&_defineProperties(e,n),e}function _inherits(e,t){if("function"!=typeof t&&null!==t)throw new TypeError("Super expression must either be null or a function");e.prototype=Object.create(t&&t.prototype,{constructor:{value:e,writable:!0,configurable:!0}}),t&&_setPrototypeOf(e,t)}function _getPrototypeOf(e){return(_getPrototypeOf=Object.setPrototypeOf?Object.getPrototypeOf:function(e){return e.__proto__||Object.getPrototypeOf(e)})(e)}function _setPrototypeOf(e,t){return(_setPrototypeOf=Object.setPrototypeOf||function(e,t){return e.__proto__=t,e})(e,t)}function _isNativeReflectConstruct(){if("undefined"==typeof Reflect||!Reflect.construct)return!1;if(Reflect.construct.sham)return!1;if("function"==typeof Proxy)return!0;try{return Date.prototype.toString.call(Reflect.construct(Date,[],function(){})),!0}catch(e){return!1}}function _assertThisInitialized(e){if(void 0===e)throw new ReferenceError("this hasn't been initialised - super() hasn't been called");return e}function _possibleConstructorReturn(e,t){return!t||"object"!=typeof t&&"function"!=typeof t?_assertThisInitialized(e):t}function _createSuper(r){var i=_isNativeReflectConstruct();return function(){var e,t=_getPrototypeOf(r);if(i){var n=_getPrototypeOf(this).constructor;e=Reflect.construct(t,arguments,n)}else e=t.apply(this,arguments);return _possibleConstructorReturn(this,e)}}function _toConsumableArray(e){return _arrayWithoutHoles(e)||_iterableToArray(e)||_unsupportedIterableToArray(e)||_nonIterableSpread()}function _arrayWithoutHoles(e){if(Array.isArray(e))return _arrayLikeToArray(e)}function _iterableToArray(e){if("undefined"!=typeof Symbol&&Symbol.iterator in Object(e))return Array.from(e)}function _unsupportedIterableToArray(e,t){if(e){if("string"==typeof e)return _arrayLikeToArray(e,t);var n=Object.prototype.toString.call(e).slice(8,-1);return"Object"===n&&e.constructor&&(n=e.constructor.name),"Map"===n||"Set"===n?Array.from(e):"Arguments"===n||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?_arrayLikeToArray(e,t):void 0}}function _arrayLikeToArray(e,t){(null==t||t>e.length)&&(t=e.length);for(var n=0,r=new Array(t);n<t;n++)r[n]=e[n];return r}function _nonIterableSpread(){throw new TypeError("Invalid attempt to spread non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.")}var Channel=function(){function c(e){_classCallCheck(this,c),this._listeners=[],this._mute=!1,this._accumulate=!1,this._accumulatedEvents=[],this._name=e||"",this._onListenerAdded=null,this._onFirstListenerAdded=null,this._onListenerRemoved=null,this._onLastListenerRemoved=null}return _createClass(c,[{key:"addListener",value:function(e,t){this._pushListener(e,t,!1)}},{key:"addOnceListener",value:function(e,t){this._pushListener(e,t,!0)}},{key:"removeListener",value:function(e,t){this._ensureListener(e);var n=this._indexOfListener(e,t);0<=n&&this._spliceListener(n)}},{key:"removeAllListeners",value:function(){for(;this.hasListeners();)this._spliceListener(0)}},{key:"hasListener",value:function(e,t){return this._ensureListener(e),0<=this._indexOfListener(e,t)}},{key:"hasListeners",value:function(){return 0<this._listeners.length}},{key:"dispatch",value:function(){for(var e=arguments.length,t=new Array(e),n=0;n<e;n++)t[n]=arguments[n];this._invokeListeners({args:t,async:!1})}},{key:"dispatchAsync",value:function(){for(var e=arguments.length,t=new Array(e),n=0;n<e;n++)t[n]=arguments[n];this._invokeListeners({args:t,async:!0})}},{key:"mute",value:function(e){var t=0<arguments.length&&void 0!==e?e:{};this._mute=!0,t.accumulate?this._accumulate=!0:(this._accumulate=!1,this._accumulatedEvents=[])}},{key:"unmute",value:function(){this._mute=!1,this._accumulate&&(this._dispatchAccumulated(),this._accumulate=!1)}},{key:"_invokeListeners",value:function(e){var t=this,n=0<arguments.length&&void 0!==e?e:{args:[],async:!1};this._mute?this._accumulate&&this._accumulatedEvents.push(n):this._listeners.slice().forEach(function(e){t._invokeListener(e,n),e.once&&t.removeListener(e.callback,e.context)})}},{key:"_invokeListener",value:function(e,t){var n,r,i=e.callback instanceof c;t.async?i?(n=e.callback).dispatchAsync.apply(n,_toConsumableArray(t.args)):setTimeout(function(){return e.callback.apply(e.context,t.args)},0):i?(r=e.callback).dispatch.apply(r,_toConsumableArray(t.args)):e.callback.apply(e.context,t.args)}},{key:"_ensureListener",value:function(e){if(!c.isValidListener(e))throw new Error("Channel "+this._name+": listener is not a function and not a Channel")}},{key:"_dispatchInnerAddEvents",value:function(){var e,t;this._onListenerAdded&&(e=this._onListenerAdded).dispatch.apply(e,arguments);this._onFirstListenerAdded&&1===this._listeners.length&&(t=this._onFirstListenerAdded).dispatch.apply(t,arguments)}},{key:"_dispatchInnerRemoveEvents",value:function(){var e,t;this._onListenerRemoved&&(e=this._onListenerRemoved).dispatch.apply(e,arguments);this._onLastListenerRemoved&&0===this._listeners.length&&(t=this._onLastListenerRemoved).dispatch.apply(t,arguments)}},{key:"_indexOfListener",value:function(e,t){for(var n=0;n<this._listeners.length;n++){var r=this._listeners[n],i=r.callback===e,s=e instanceof c,o=void 0===t&&void 0===r.context,a=t===r.context;if(i&&(s||o||a))return n}}},{key:"_dispatchAccumulated",value:function(){var t=this;this._accumulatedEvents.forEach(function(e){return t._invokeListeners(e)}),this._accumulatedEvents=[]}},{key:"_pushListener",value:function(e,t,n){this._ensureListener(e),this._checkForDuplicates(e,t),this._listeners.push({callback:e,context:t,once:n}),this._dispatchInnerAddEvents(e,t,n)}},{key:"_checkForDuplicates",value:function(e,t){if(this.hasListener(e,t))throw new Error("Channel "+this._name+": duplicating listeners")}},{key:"_spliceListener",value:function(e){var t=this._listeners[e],n=t.callback,r=t.context,i=t.once;this._listeners.splice(e,1),this._dispatchInnerRemoveEvents(n,r,i)}},{key:"onListenerAdded",get:function(){return this._onListenerAdded||(this._onListenerAdded=new c("".concat(this._name,":onListenerAdded"))),this._onListenerAdded}},{key:"onFirstListenerAdded",get:function(){return this._onFirstListenerAdded||(this._onFirstListenerAdded=new c("".concat(this._name,":onFirstListenerAdded"))),this._onFirstListenerAdded}},{key:"onListenerRemoved",get:function(){return this._onListenerRemoved||(this._onListenerRemoved=new c("".concat(this._name,":onListenerRemoved"))),this._onListenerRemoved}},{key:"onLastListenerRemoved",get:function(){return this._onLastListenerRemoved||(this._onLastListenerRemoved=new c("".concat(this._name,":onLastListenerRemoved"))),this._onLastListenerRemoved}}],[{key:"isValidListener",value:function(e){return"function"==typeof e||e instanceof c}}]),c}(),EventEmitter=function(){function e(){_classCallCheck(this,e),this._channels=new Map}return _createClass(e,[{key:"addListener",value:function(e,t,n){this._getChannel(e).addListener(t,n)}},{key:"on",value:function(e,t,n){this.addListener(e,t,n)}},{key:"addOnceListener",value:function(e,t,n){this._getChannel(e).addOnceListener(t,n)}},{key:"once",value:function(e,t,n){this.addOnceListener(e,t,n)}},{key:"removeListener",value:function(e,t,n){this._getChannel(e).removeListener(t,n)}},{key:"off",value:function(e,t,n){this.removeListener(e,t,n)}},{key:"hasListener",value:function(e,t,n){return this._getChannel(e).hasListener(t,n)}},{key:"has",value:function(e,t,n){return this.hasListener(e,t,n)}},{key:"hasListeners",value:function(e){return this._getChannel(e).hasListeners()}},{key:"dispatch",value:function(e){for(var t,n=arguments.length,r=new Array(1<n?n-1:0),i=1;i<n;i++)r[i-1]=arguments[i];(t=this._getChannel(e)).dispatch.apply(t,r)}},{key:"emit",value:function(e){for(var t=arguments.length,n=new Array(1<t?t-1:0),r=1;r<t;r++)n[r-1]=arguments[r];this.dispatch.apply(this,[e].concat(n))}},{key:"_getChannel",value:function(e){return this._channels.has(e)||this._channels.set(e,new Channel(e)),this._channels.get(e)}}]),e}(),SubscriptionItem=function(){function t(e){_classCallCheck(this,t),this._params=e,this._isOn=!1,this._assertParams()}return _createClass(t,[{key:"on",value:function(){if(!this._isOn){var e=this._params.channel,t=e.addListener||e.addEventListener||e.on;this._applyMethod(t),this._isOn=!0}}},{key:"off",value:function(){if(this._isOn){var e=this._params.channel,t=e.removeListener||e.removeEventListener||e.off;this._applyMethod(t),this._isOn=!1}}},{key:"_applyMethod",value:function(e){var t=this._params,n=t.channel,r=t.event,i=t.listener,s=r?[r,i]:[i];e.apply(n,s)}},{key:"_assertParams",value:function(){var e=this._params,t=e.channel,n=e.event,r=e.listener;if(!t||"object"!==_typeof(t))throw new Error("Channel should be object");if(n&&"string"!=typeof n)throw new Error("Event should be string");if(!r||!Channel.isValidListener(r))throw new Error("Listener should be function or Channel")}}]),t}(),Subscription=function(){function t(e){_classCallCheck(this,t),this._items=e.map(function(e){return new SubscriptionItem(e)})}return _createClass(t,[{key:"on",value:function(){return this._items.forEach(function(e){return e.on()}),this}},{key:"off",value:function(){return this._items.forEach(function(e){return e.off()}),this}}]),t}(),ReactSubscription=function(){_inherits(i,Subscription);var r=_createSuper(i);function i(e,t){var n;return _classCallCheck(this,i),(n=r.call(this,t))._overrideComponentCallback(e,"componentDidMount","on"),n._overrideComponentCallback(e,"componentWillUnmount","off"),n}return _createClass(i,[{key:"_overrideComponentCallback",value:function(r,e,i){var s=this,o=r[e];r[e]=function(){if(s[i](),"function"==typeof o){for(var e=arguments.length,t=new Array(e),n=0;n<e;n++)t[n]=arguments[n];return o.apply(r,t)}}}}]),i}(),chnl=Channel;chnl.EventEmitter=EventEmitter,chnl.Subscription=Subscription,chnl.ReactSubscription=ReactSubscription,module.exports=chnl;

},{}],4:[function(require,module,exports){
'use strict';

var keys = require('object-keys');
var hasSymbols = typeof Symbol === 'function' && typeof Symbol('foo') === 'symbol';

var toStr = Object.prototype.toString;
var concat = Array.prototype.concat;
var origDefineProperty = Object.defineProperty;

var isFunction = function (fn) {
	return typeof fn === 'function' && toStr.call(fn) === '[object Function]';
};

var arePropertyDescriptorsSupported = function () {
	var obj = {};
	try {
		origDefineProperty(obj, 'x', { enumerable: false, value: obj });
		// eslint-disable-next-line no-unused-vars, no-restricted-syntax
		for (var _ in obj) { // jscs:ignore disallowUnusedVariables
			return false;
		}
		return obj.x === obj;
	} catch (e) { /* this is IE 8. */
		return false;
	}
};
var supportsDescriptors = origDefineProperty && arePropertyDescriptorsSupported();

var defineProperty = function (object, name, value, predicate) {
	if (name in object && (!isFunction(predicate) || !predicate())) {
		return;
	}
	if (supportsDescriptors) {
		origDefineProperty(object, name, {
			configurable: true,
			enumerable: false,
			value: value,
			writable: true
		});
	} else {
		object[name] = value;
	}
};

var defineProperties = function (object, map) {
	var predicates = arguments.length > 2 ? arguments[2] : {};
	var props = keys(map);
	if (hasSymbols) {
		props = concat.call(props, Object.getOwnPropertySymbols(map));
	}
	for (var i = 0; i < props.length; i += 1) {
		defineProperty(object, props[i], map[props[i]], predicates[props[i]]);
	}
};

defineProperties.supportsDescriptors = !!supportsDescriptors;

module.exports = defineProperties;

},{"object-keys":32}],5:[function(require,module,exports){
'use strict';

var GetIntrinsic = require('get-intrinsic');

var $Array = GetIntrinsic('%Array%');

// eslint-disable-next-line global-require
var toStr = !$Array.isArray && require('call-bind/callBound')('Object.prototype.toString');

// https://ecma-international.org/ecma-262/6.0/#sec-isarray

module.exports = $Array.isArray || function IsArray(argument) {
	return toStr(argument) === '[object Array]';
};

},{"call-bind/callBound":1,"get-intrinsic":26}],6:[function(require,module,exports){
'use strict';

var GetIntrinsic = require('get-intrinsic');

var $TypeError = GetIntrinsic('%TypeError%');

var isPropertyDescriptor = require('../helpers/isPropertyDescriptor');
var DefineOwnProperty = require('../helpers/DefineOwnProperty');

var FromPropertyDescriptor = require('./FromPropertyDescriptor');
var IsAccessorDescriptor = require('./IsAccessorDescriptor');
var IsDataDescriptor = require('./IsDataDescriptor');
var IsPropertyKey = require('./IsPropertyKey');
var SameValue = require('./SameValue');
var ToPropertyDescriptor = require('./ToPropertyDescriptor');
var Type = require('./Type');

// https://ecma-international.org/ecma-262/6.0/#sec-definepropertyorthrow

module.exports = function DefinePropertyOrThrow(O, P, desc) {
	if (Type(O) !== 'Object') {
		throw new $TypeError('Assertion failed: Type(O) is not Object');
	}

	if (!IsPropertyKey(P)) {
		throw new $TypeError('Assertion failed: IsPropertyKey(P) is not true');
	}

	var Desc = isPropertyDescriptor({
		Type: Type,
		IsDataDescriptor: IsDataDescriptor,
		IsAccessorDescriptor: IsAccessorDescriptor
	}, desc) ? desc : ToPropertyDescriptor(desc);
	if (!isPropertyDescriptor({
		Type: Type,
		IsDataDescriptor: IsDataDescriptor,
		IsAccessorDescriptor: IsAccessorDescriptor
	}, Desc)) {
		throw new $TypeError('Assertion failed: Desc is not a valid Property Descriptor');
	}

	return DefineOwnProperty(
		IsDataDescriptor,
		SameValue,
		FromPropertyDescriptor,
		O,
		P,
		Desc
	);
};

},{"../helpers/DefineOwnProperty":20,"../helpers/isPropertyDescriptor":23,"./FromPropertyDescriptor":7,"./IsAccessorDescriptor":8,"./IsDataDescriptor":11,"./IsPropertyKey":12,"./SameValue":13,"./ToPropertyDescriptor":16,"./Type":17,"get-intrinsic":26}],7:[function(require,module,exports){
'use strict';

var assertRecord = require('../helpers/assertRecord');

var Type = require('./Type');

// https://ecma-international.org/ecma-262/6.0/#sec-frompropertydescriptor

module.exports = function FromPropertyDescriptor(Desc) {
	if (typeof Desc === 'undefined') {
		return Desc;
	}

	assertRecord(Type, 'Property Descriptor', 'Desc', Desc);

	var obj = {};
	if ('[[Value]]' in Desc) {
		obj.value = Desc['[[Value]]'];
	}
	if ('[[Writable]]' in Desc) {
		obj.writable = Desc['[[Writable]]'];
	}
	if ('[[Get]]' in Desc) {
		obj.get = Desc['[[Get]]'];
	}
	if ('[[Set]]' in Desc) {
		obj.set = Desc['[[Set]]'];
	}
	if ('[[Enumerable]]' in Desc) {
		obj.enumerable = Desc['[[Enumerable]]'];
	}
	if ('[[Configurable]]' in Desc) {
		obj.configurable = Desc['[[Configurable]]'];
	}
	return obj;
};

},{"../helpers/assertRecord":21,"./Type":17}],8:[function(require,module,exports){
'use strict';

var has = require('has');

var assertRecord = require('../helpers/assertRecord');

var Type = require('./Type');

// https://ecma-international.org/ecma-262/6.0/#sec-isaccessordescriptor

module.exports = function IsAccessorDescriptor(Desc) {
	if (typeof Desc === 'undefined') {
		return false;
	}

	assertRecord(Type, 'Property Descriptor', 'Desc', Desc);

	if (!has(Desc, '[[Get]]') && !has(Desc, '[[Set]]')) {
		return false;
	}

	return true;
};

},{"../helpers/assertRecord":21,"./Type":17,"has":29}],9:[function(require,module,exports){
'use strict';

// http://262.ecma-international.org/5.1/#sec-9.11

module.exports = require('is-callable');

},{"is-callable":30}],10:[function(require,module,exports){
'use strict';

var GetIntrinsic = require('../GetIntrinsic.js');

var $construct = GetIntrinsic('%Reflect.construct%', true);

var DefinePropertyOrThrow = require('./DefinePropertyOrThrow');
try {
	DefinePropertyOrThrow({}, '', { '[[Get]]': function () {} });
} catch (e) {
	// Accessor properties aren't supported
	DefinePropertyOrThrow = null;
}

// https://ecma-international.org/ecma-262/6.0/#sec-isconstructor

if (DefinePropertyOrThrow && $construct) {
	var isConstructorMarker = {};
	var badArrayLike = {};
	DefinePropertyOrThrow(badArrayLike, 'length', {
		'[[Get]]': function () {
			throw isConstructorMarker;
		},
		'[[Enumerable]]': true
	});

	module.exports = function IsConstructor(argument) {
		try {
			// `Reflect.construct` invokes `IsConstructor(target)` before `Get(args, 'length')`:
			$construct(argument, badArrayLike);
		} catch (err) {
			return err === isConstructorMarker;
		}
	};
} else {
	module.exports = function IsConstructor(argument) {
		// unfortunately there's no way to truly check this without try/catch `new argument` in old environments
		return typeof argument === 'function' && !!argument.prototype;
	};
}

},{"../GetIntrinsic.js":19,"./DefinePropertyOrThrow":6}],11:[function(require,module,exports){
'use strict';

var has = require('has');

var assertRecord = require('../helpers/assertRecord');

var Type = require('./Type');

// https://ecma-international.org/ecma-262/6.0/#sec-isdatadescriptor

module.exports = function IsDataDescriptor(Desc) {
	if (typeof Desc === 'undefined') {
		return false;
	}

	assertRecord(Type, 'Property Descriptor', 'Desc', Desc);

	if (!has(Desc, '[[Value]]') && !has(Desc, '[[Writable]]')) {
		return false;
	}

	return true;
};

},{"../helpers/assertRecord":21,"./Type":17,"has":29}],12:[function(require,module,exports){
'use strict';

// https://ecma-international.org/ecma-262/6.0/#sec-ispropertykey

module.exports = function IsPropertyKey(argument) {
	return typeof argument === 'string' || typeof argument === 'symbol';
};

},{}],13:[function(require,module,exports){
'use strict';

var $isNaN = require('../helpers/isNaN');

// http://262.ecma-international.org/5.1/#sec-9.12

module.exports = function SameValue(x, y) {
	if (x === y) { // 0 === -0, but they are not identical.
		if (x === 0) { return 1 / x === 1 / y; }
		return true;
	}
	return $isNaN(x) && $isNaN(y);
};

},{"../helpers/isNaN":22}],14:[function(require,module,exports){
'use strict';

var GetIntrinsic = require('get-intrinsic');

var $species = GetIntrinsic('%Symbol.species%', true);
var $TypeError = GetIntrinsic('%TypeError%');

var IsConstructor = require('./IsConstructor');
var Type = require('./Type');

// https://ecma-international.org/ecma-262/6.0/#sec-speciesconstructor

module.exports = function SpeciesConstructor(O, defaultConstructor) {
	if (Type(O) !== 'Object') {
		throw new $TypeError('Assertion failed: Type(O) is not Object');
	}
	var C = O.constructor;
	if (typeof C === 'undefined') {
		return defaultConstructor;
	}
	if (Type(C) !== 'Object') {
		throw new $TypeError('O.constructor is not an Object');
	}
	var S = $species ? C[$species] : void 0;
	if (S == null) {
		return defaultConstructor;
	}
	if (IsConstructor(S)) {
		return S;
	}
	throw new $TypeError('no constructor found');
};

},{"./IsConstructor":10,"./Type":17,"get-intrinsic":26}],15:[function(require,module,exports){
'use strict';

// http://262.ecma-international.org/5.1/#sec-9.2

module.exports = function ToBoolean(value) { return !!value; };

},{}],16:[function(require,module,exports){
'use strict';

var has = require('has');

var GetIntrinsic = require('get-intrinsic');

var $TypeError = GetIntrinsic('%TypeError%');

var Type = require('./Type');
var ToBoolean = require('./ToBoolean');
var IsCallable = require('./IsCallable');

// https://262.ecma-international.org/5.1/#sec-8.10.5

module.exports = function ToPropertyDescriptor(Obj) {
	if (Type(Obj) !== 'Object') {
		throw new $TypeError('ToPropertyDescriptor requires an object');
	}

	var desc = {};
	if (has(Obj, 'enumerable')) {
		desc['[[Enumerable]]'] = ToBoolean(Obj.enumerable);
	}
	if (has(Obj, 'configurable')) {
		desc['[[Configurable]]'] = ToBoolean(Obj.configurable);
	}
	if (has(Obj, 'value')) {
		desc['[[Value]]'] = Obj.value;
	}
	if (has(Obj, 'writable')) {
		desc['[[Writable]]'] = ToBoolean(Obj.writable);
	}
	if (has(Obj, 'get')) {
		var getter = Obj.get;
		if (typeof getter !== 'undefined' && !IsCallable(getter)) {
			throw new $TypeError('getter must be a function');
		}
		desc['[[Get]]'] = getter;
	}
	if (has(Obj, 'set')) {
		var setter = Obj.set;
		if (typeof setter !== 'undefined' && !IsCallable(setter)) {
			throw new $TypeError('setter must be a function');
		}
		desc['[[Set]]'] = setter;
	}

	if ((has(desc, '[[Get]]') || has(desc, '[[Set]]')) && (has(desc, '[[Value]]') || has(desc, '[[Writable]]'))) {
		throw new $TypeError('Invalid property descriptor. Cannot both specify accessors and a value or writable attribute');
	}
	return desc;
};

},{"./IsCallable":9,"./ToBoolean":15,"./Type":17,"get-intrinsic":26,"has":29}],17:[function(require,module,exports){
'use strict';

var ES5Type = require('../5/Type');

// https://262.ecma-international.org/11.0/#sec-ecmascript-data-types-and-values

module.exports = function Type(x) {
	if (typeof x === 'symbol') {
		return 'Symbol';
	}
	if (typeof x === 'bigint') {
		return 'BigInt';
	}
	return ES5Type(x);
};

},{"../5/Type":18}],18:[function(require,module,exports){
'use strict';

// https://262.ecma-international.org/5.1/#sec-8

module.exports = function Type(x) {
	if (x === null) {
		return 'Null';
	}
	if (typeof x === 'undefined') {
		return 'Undefined';
	}
	if (typeof x === 'function' || typeof x === 'object') {
		return 'Object';
	}
	if (typeof x === 'number') {
		return 'Number';
	}
	if (typeof x === 'boolean') {
		return 'Boolean';
	}
	if (typeof x === 'string') {
		return 'String';
	}
};

},{}],19:[function(require,module,exports){
'use strict';

// TODO: remove, semver-major

module.exports = require('get-intrinsic');

},{"get-intrinsic":26}],20:[function(require,module,exports){
'use strict';

var GetIntrinsic = require('get-intrinsic');

var $defineProperty = GetIntrinsic('%Object.defineProperty%', true);

if ($defineProperty) {
	try {
		$defineProperty({}, 'a', { value: 1 });
	} catch (e) {
		// IE 8 has a broken defineProperty
		$defineProperty = null;
	}
}

// node v0.6 has a bug where array lengths can be Set but not Defined
var hasArrayLengthDefineBug = Object.defineProperty && Object.defineProperty([], 'length', { value: 1 }).length === 0;

// eslint-disable-next-line global-require
var isArray = hasArrayLengthDefineBug && require('../2020/IsArray'); // this does not depend on any other AOs.

var callBound = require('call-bind/callBound');

var $isEnumerable = callBound('Object.prototype.propertyIsEnumerable');

// eslint-disable-next-line max-params
module.exports = function DefineOwnProperty(IsDataDescriptor, SameValue, FromPropertyDescriptor, O, P, desc) {
	if (!$defineProperty) {
		if (!IsDataDescriptor(desc)) {
			// ES3 does not support getters/setters
			return false;
		}
		if (!desc['[[Configurable]]'] || !desc['[[Writable]]']) {
			return false;
		}

		// fallback for ES3
		if (P in O && $isEnumerable(O, P) !== !!desc['[[Enumerable]]']) {
			// a non-enumerable existing property
			return false;
		}

		// property does not exist at all, or exists but is enumerable
		var V = desc['[[Value]]'];
		// eslint-disable-next-line no-param-reassign
		O[P] = V; // will use [[Define]]
		return SameValue(O[P], V);
	}
	if (
		hasArrayLengthDefineBug
		&& P === 'length'
		&& '[[Value]]' in desc
		&& isArray(O)
		&& O.length !== desc['[[Value]]']
	) {
		// eslint-disable-next-line no-param-reassign
		O.length = desc['[[Value]]'];
		return O.length === desc['[[Value]]'];
	}

	$defineProperty(O, P, FromPropertyDescriptor(desc));
	return true;
};

},{"../2020/IsArray":5,"call-bind/callBound":1,"get-intrinsic":26}],21:[function(require,module,exports){
'use strict';

var GetIntrinsic = require('get-intrinsic');

var $TypeError = GetIntrinsic('%TypeError%');
var $SyntaxError = GetIntrinsic('%SyntaxError%');

var has = require('has');

var predicates = {
	// https://262.ecma-international.org/6.0/#sec-property-descriptor-specification-type
	'Property Descriptor': function isPropertyDescriptor(Type, Desc) {
		if (Type(Desc) !== 'Object') {
			return false;
		}
		var allowed = {
			'[[Configurable]]': true,
			'[[Enumerable]]': true,
			'[[Get]]': true,
			'[[Set]]': true,
			'[[Value]]': true,
			'[[Writable]]': true
		};

		for (var key in Desc) { // eslint-disable-line
			if (has(Desc, key) && !allowed[key]) {
				return false;
			}
		}

		var isData = has(Desc, '[[Value]]');
		var IsAccessor = has(Desc, '[[Get]]') || has(Desc, '[[Set]]');
		if (isData && IsAccessor) {
			throw new $TypeError('Property Descriptors may not be both accessor and data descriptors');
		}
		return true;
	}
};

module.exports = function assertRecord(Type, recordType, argumentName, value) {
	var predicate = predicates[recordType];
	if (typeof predicate !== 'function') {
		throw new $SyntaxError('unknown record type: ' + recordType);
	}
	if (!predicate(Type, value)) {
		throw new $TypeError(argumentName + ' must be a ' + recordType);
	}
};

},{"get-intrinsic":26,"has":29}],22:[function(require,module,exports){
'use strict';

module.exports = Number.isNaN || function isNaN(a) {
	return a !== a;
};

},{}],23:[function(require,module,exports){
'use strict';

var GetIntrinsic = require('get-intrinsic');

var has = require('has');
var $TypeError = GetIntrinsic('%TypeError%');

module.exports = function IsPropertyDescriptor(ES, Desc) {
	if (ES.Type(Desc) !== 'Object') {
		return false;
	}
	var allowed = {
		'[[Configurable]]': true,
		'[[Enumerable]]': true,
		'[[Get]]': true,
		'[[Set]]': true,
		'[[Value]]': true,
		'[[Writable]]': true
	};

	for (var key in Desc) { // eslint-disable-line no-restricted-syntax
		if (has(Desc, key) && !allowed[key]) {
			return false;
		}
	}

	if (ES.IsDataDescriptor(Desc) && ES.IsAccessorDescriptor(Desc)) {
		throw new $TypeError('Property Descriptors may not be both accessor and data descriptors');
	}
	return true;
};

},{"get-intrinsic":26,"has":29}],24:[function(require,module,exports){
'use strict';

/* eslint no-invalid-this: 1 */

var ERROR_MESSAGE = 'Function.prototype.bind called on incompatible ';
var slice = Array.prototype.slice;
var toStr = Object.prototype.toString;
var funcType = '[object Function]';

module.exports = function bind(that) {
    var target = this;
    if (typeof target !== 'function' || toStr.call(target) !== funcType) {
        throw new TypeError(ERROR_MESSAGE + target);
    }
    var args = slice.call(arguments, 1);

    var bound;
    var binder = function () {
        if (this instanceof bound) {
            var result = target.apply(
                this,
                args.concat(slice.call(arguments))
            );
            if (Object(result) === result) {
                return result;
            }
            return this;
        } else {
            return target.apply(
                that,
                args.concat(slice.call(arguments))
            );
        }
    };

    var boundLength = Math.max(0, target.length - args.length);
    var boundArgs = [];
    for (var i = 0; i < boundLength; i++) {
        boundArgs.push('$' + i);
    }

    bound = Function('binder', 'return function (' + boundArgs.join(',') + '){ return binder.apply(this,arguments); }')(binder);

    if (target.prototype) {
        var Empty = function Empty() {};
        Empty.prototype = target.prototype;
        bound.prototype = new Empty();
        Empty.prototype = null;
    }

    return bound;
};

},{}],25:[function(require,module,exports){
'use strict';

var implementation = require('./implementation');

module.exports = Function.prototype.bind || implementation;

},{"./implementation":24}],26:[function(require,module,exports){
'use strict';

var undefined;

var $SyntaxError = SyntaxError;
var $Function = Function;
var $TypeError = TypeError;

// eslint-disable-next-line consistent-return
var getEvalledConstructor = function (expressionSyntax) {
	try {
		return $Function('"use strict"; return (' + expressionSyntax + ').constructor;')();
	} catch (e) {}
};

var $gOPD = Object.getOwnPropertyDescriptor;
if ($gOPD) {
	try {
		$gOPD({}, '');
	} catch (e) {
		$gOPD = null; // this is IE 8, which has a broken gOPD
	}
}

var throwTypeError = function () {
	throw new $TypeError();
};
var ThrowTypeError = $gOPD
	? (function () {
		try {
			// eslint-disable-next-line no-unused-expressions, no-caller, no-restricted-properties
			arguments.callee; // IE 8 does not throw here
			return throwTypeError;
		} catch (calleeThrows) {
			try {
				// IE 8 throws on Object.getOwnPropertyDescriptor(arguments, '')
				return $gOPD(arguments, 'callee').get;
			} catch (gOPDthrows) {
				return throwTypeError;
			}
		}
	}())
	: throwTypeError;

var hasSymbols = require('has-symbols')();

var getProto = Object.getPrototypeOf || function (x) { return x.__proto__; }; // eslint-disable-line no-proto

var needsEval = {};

var TypedArray = typeof Uint8Array === 'undefined' ? undefined : getProto(Uint8Array);

var INTRINSICS = {
	'%AggregateError%': typeof AggregateError === 'undefined' ? undefined : AggregateError,
	'%Array%': Array,
	'%ArrayBuffer%': typeof ArrayBuffer === 'undefined' ? undefined : ArrayBuffer,
	'%ArrayIteratorPrototype%': hasSymbols ? getProto([][Symbol.iterator]()) : undefined,
	'%AsyncFromSyncIteratorPrototype%': undefined,
	'%AsyncFunction%': needsEval,
	'%AsyncGenerator%': needsEval,
	'%AsyncGeneratorFunction%': needsEval,
	'%AsyncIteratorPrototype%': needsEval,
	'%Atomics%': typeof Atomics === 'undefined' ? undefined : Atomics,
	'%BigInt%': typeof BigInt === 'undefined' ? undefined : BigInt,
	'%Boolean%': Boolean,
	'%DataView%': typeof DataView === 'undefined' ? undefined : DataView,
	'%Date%': Date,
	'%decodeURI%': decodeURI,
	'%decodeURIComponent%': decodeURIComponent,
	'%encodeURI%': encodeURI,
	'%encodeURIComponent%': encodeURIComponent,
	'%Error%': Error,
	'%eval%': eval, // eslint-disable-line no-eval
	'%EvalError%': EvalError,
	'%Float32Array%': typeof Float32Array === 'undefined' ? undefined : Float32Array,
	'%Float64Array%': typeof Float64Array === 'undefined' ? undefined : Float64Array,
	'%FinalizationRegistry%': typeof FinalizationRegistry === 'undefined' ? undefined : FinalizationRegistry,
	'%Function%': $Function,
	'%GeneratorFunction%': needsEval,
	'%Int8Array%': typeof Int8Array === 'undefined' ? undefined : Int8Array,
	'%Int16Array%': typeof Int16Array === 'undefined' ? undefined : Int16Array,
	'%Int32Array%': typeof Int32Array === 'undefined' ? undefined : Int32Array,
	'%isFinite%': isFinite,
	'%isNaN%': isNaN,
	'%IteratorPrototype%': hasSymbols ? getProto(getProto([][Symbol.iterator]())) : undefined,
	'%JSON%': typeof JSON === 'object' ? JSON : undefined,
	'%Map%': typeof Map === 'undefined' ? undefined : Map,
	'%MapIteratorPrototype%': typeof Map === 'undefined' || !hasSymbols ? undefined : getProto(new Map()[Symbol.iterator]()),
	'%Math%': Math,
	'%Number%': Number,
	'%Object%': Object,
	'%parseFloat%': parseFloat,
	'%parseInt%': parseInt,
	'%Promise%': typeof Promise === 'undefined' ? undefined : Promise,
	'%Proxy%': typeof Proxy === 'undefined' ? undefined : Proxy,
	'%RangeError%': RangeError,
	'%ReferenceError%': ReferenceError,
	'%Reflect%': typeof Reflect === 'undefined' ? undefined : Reflect,
	'%RegExp%': RegExp,
	'%Set%': typeof Set === 'undefined' ? undefined : Set,
	'%SetIteratorPrototype%': typeof Set === 'undefined' || !hasSymbols ? undefined : getProto(new Set()[Symbol.iterator]()),
	'%SharedArrayBuffer%': typeof SharedArrayBuffer === 'undefined' ? undefined : SharedArrayBuffer,
	'%String%': String,
	'%StringIteratorPrototype%': hasSymbols ? getProto(''[Symbol.iterator]()) : undefined,
	'%Symbol%': hasSymbols ? Symbol : undefined,
	'%SyntaxError%': $SyntaxError,
	'%ThrowTypeError%': ThrowTypeError,
	'%TypedArray%': TypedArray,
	'%TypeError%': $TypeError,
	'%Uint8Array%': typeof Uint8Array === 'undefined' ? undefined : Uint8Array,
	'%Uint8ClampedArray%': typeof Uint8ClampedArray === 'undefined' ? undefined : Uint8ClampedArray,
	'%Uint16Array%': typeof Uint16Array === 'undefined' ? undefined : Uint16Array,
	'%Uint32Array%': typeof Uint32Array === 'undefined' ? undefined : Uint32Array,
	'%URIError%': URIError,
	'%WeakMap%': typeof WeakMap === 'undefined' ? undefined : WeakMap,
	'%WeakRef%': typeof WeakRef === 'undefined' ? undefined : WeakRef,
	'%WeakSet%': typeof WeakSet === 'undefined' ? undefined : WeakSet
};

var doEval = function doEval(name) {
	var value;
	if (name === '%AsyncFunction%') {
		value = getEvalledConstructor('async function () {}');
	} else if (name === '%GeneratorFunction%') {
		value = getEvalledConstructor('function* () {}');
	} else if (name === '%AsyncGeneratorFunction%') {
		value = getEvalledConstructor('async function* () {}');
	} else if (name === '%AsyncGenerator%') {
		var fn = doEval('%AsyncGeneratorFunction%');
		if (fn) {
			value = fn.prototype;
		}
	} else if (name === '%AsyncIteratorPrototype%') {
		var gen = doEval('%AsyncGenerator%');
		if (gen) {
			value = getProto(gen.prototype);
		}
	}

	INTRINSICS[name] = value;

	return value;
};

var LEGACY_ALIASES = {
	'%ArrayBufferPrototype%': ['ArrayBuffer', 'prototype'],
	'%ArrayPrototype%': ['Array', 'prototype'],
	'%ArrayProto_entries%': ['Array', 'prototype', 'entries'],
	'%ArrayProto_forEach%': ['Array', 'prototype', 'forEach'],
	'%ArrayProto_keys%': ['Array', 'prototype', 'keys'],
	'%ArrayProto_values%': ['Array', 'prototype', 'values'],
	'%AsyncFunctionPrototype%': ['AsyncFunction', 'prototype'],
	'%AsyncGenerator%': ['AsyncGeneratorFunction', 'prototype'],
	'%AsyncGeneratorPrototype%': ['AsyncGeneratorFunction', 'prototype', 'prototype'],
	'%BooleanPrototype%': ['Boolean', 'prototype'],
	'%DataViewPrototype%': ['DataView', 'prototype'],
	'%DatePrototype%': ['Date', 'prototype'],
	'%ErrorPrototype%': ['Error', 'prototype'],
	'%EvalErrorPrototype%': ['EvalError', 'prototype'],
	'%Float32ArrayPrototype%': ['Float32Array', 'prototype'],
	'%Float64ArrayPrototype%': ['Float64Array', 'prototype'],
	'%FunctionPrototype%': ['Function', 'prototype'],
	'%Generator%': ['GeneratorFunction', 'prototype'],
	'%GeneratorPrototype%': ['GeneratorFunction', 'prototype', 'prototype'],
	'%Int8ArrayPrototype%': ['Int8Array', 'prototype'],
	'%Int16ArrayPrototype%': ['Int16Array', 'prototype'],
	'%Int32ArrayPrototype%': ['Int32Array', 'prototype'],
	'%JSONParse%': ['JSON', 'parse'],
	'%JSONStringify%': ['JSON', 'stringify'],
	'%MapPrototype%': ['Map', 'prototype'],
	'%NumberPrototype%': ['Number', 'prototype'],
	'%ObjectPrototype%': ['Object', 'prototype'],
	'%ObjProto_toString%': ['Object', 'prototype', 'toString'],
	'%ObjProto_valueOf%': ['Object', 'prototype', 'valueOf'],
	'%PromisePrototype%': ['Promise', 'prototype'],
	'%PromiseProto_then%': ['Promise', 'prototype', 'then'],
	'%Promise_all%': ['Promise', 'all'],
	'%Promise_reject%': ['Promise', 'reject'],
	'%Promise_resolve%': ['Promise', 'resolve'],
	'%RangeErrorPrototype%': ['RangeError', 'prototype'],
	'%ReferenceErrorPrototype%': ['ReferenceError', 'prototype'],
	'%RegExpPrototype%': ['RegExp', 'prototype'],
	'%SetPrototype%': ['Set', 'prototype'],
	'%SharedArrayBufferPrototype%': ['SharedArrayBuffer', 'prototype'],
	'%StringPrototype%': ['String', 'prototype'],
	'%SymbolPrototype%': ['Symbol', 'prototype'],
	'%SyntaxErrorPrototype%': ['SyntaxError', 'prototype'],
	'%TypedArrayPrototype%': ['TypedArray', 'prototype'],
	'%TypeErrorPrototype%': ['TypeError', 'prototype'],
	'%Uint8ArrayPrototype%': ['Uint8Array', 'prototype'],
	'%Uint8ClampedArrayPrototype%': ['Uint8ClampedArray', 'prototype'],
	'%Uint16ArrayPrototype%': ['Uint16Array', 'prototype'],
	'%Uint32ArrayPrototype%': ['Uint32Array', 'prototype'],
	'%URIErrorPrototype%': ['URIError', 'prototype'],
	'%WeakMapPrototype%': ['WeakMap', 'prototype'],
	'%WeakSetPrototype%': ['WeakSet', 'prototype']
};

var bind = require('function-bind');
var hasOwn = require('has');
var $concat = bind.call(Function.call, Array.prototype.concat);
var $spliceApply = bind.call(Function.apply, Array.prototype.splice);
var $replace = bind.call(Function.call, String.prototype.replace);
var $strSlice = bind.call(Function.call, String.prototype.slice);

/* adapted from https://github.com/lodash/lodash/blob/4.17.15/dist/lodash.js#L6735-L6744 */
var rePropName = /[^%.[\]]+|\[(?:(-?\d+(?:\.\d+)?)|(["'])((?:(?!\2)[^\\]|\\.)*?)\2)\]|(?=(?:\.|\[\])(?:\.|\[\]|%$))/g;
var reEscapeChar = /\\(\\)?/g; /** Used to match backslashes in property paths. */
var stringToPath = function stringToPath(string) {
	var first = $strSlice(string, 0, 1);
	var last = $strSlice(string, -1);
	if (first === '%' && last !== '%') {
		throw new $SyntaxError('invalid intrinsic syntax, expected closing `%`');
	} else if (last === '%' && first !== '%') {
		throw new $SyntaxError('invalid intrinsic syntax, expected opening `%`');
	}
	var result = [];
	$replace(string, rePropName, function (match, number, quote, subString) {
		result[result.length] = quote ? $replace(subString, reEscapeChar, '$1') : number || match;
	});
	return result;
};
/* end adaptation */

var getBaseIntrinsic = function getBaseIntrinsic(name, allowMissing) {
	var intrinsicName = name;
	var alias;
	if (hasOwn(LEGACY_ALIASES, intrinsicName)) {
		alias = LEGACY_ALIASES[intrinsicName];
		intrinsicName = '%' + alias[0] + '%';
	}

	if (hasOwn(INTRINSICS, intrinsicName)) {
		var value = INTRINSICS[intrinsicName];
		if (value === needsEval) {
			value = doEval(intrinsicName);
		}
		if (typeof value === 'undefined' && !allowMissing) {
			throw new $TypeError('intrinsic ' + name + ' exists, but is not available. Please file an issue!');
		}

		return {
			alias: alias,
			name: intrinsicName,
			value: value
		};
	}

	throw new $SyntaxError('intrinsic ' + name + ' does not exist!');
};

module.exports = function GetIntrinsic(name, allowMissing) {
	if (typeof name !== 'string' || name.length === 0) {
		throw new $TypeError('intrinsic name must be a non-empty string');
	}
	if (arguments.length > 1 && typeof allowMissing !== 'boolean') {
		throw new $TypeError('"allowMissing" argument must be a boolean');
	}

	var parts = stringToPath(name);
	var intrinsicBaseName = parts.length > 0 ? parts[0] : '';

	var intrinsic = getBaseIntrinsic('%' + intrinsicBaseName + '%', allowMissing);
	var intrinsicRealName = intrinsic.name;
	var value = intrinsic.value;
	var skipFurtherCaching = false;

	var alias = intrinsic.alias;
	if (alias) {
		intrinsicBaseName = alias[0];
		$spliceApply(parts, $concat([0, 1], alias));
	}

	for (var i = 1, isOwn = true; i < parts.length; i += 1) {
		var part = parts[i];
		var first = $strSlice(part, 0, 1);
		var last = $strSlice(part, -1);
		if (
			(
				(first === '"' || first === "'" || first === '`')
				|| (last === '"' || last === "'" || last === '`')
			)
			&& first !== last
		) {
			throw new $SyntaxError('property names with quotes must have matching quotes');
		}
		if (part === 'constructor' || !isOwn) {
			skipFurtherCaching = true;
		}

		intrinsicBaseName += '.' + part;
		intrinsicRealName = '%' + intrinsicBaseName + '%';

		if (hasOwn(INTRINSICS, intrinsicRealName)) {
			value = INTRINSICS[intrinsicRealName];
		} else if (value != null) {
			if (!(part in value)) {
				if (!allowMissing) {
					throw new $TypeError('base intrinsic for ' + name + ' exists, but the property is not available.');
				}
				return void undefined;
			}
			if ($gOPD && (i + 1) >= parts.length) {
				var desc = $gOPD(value, part);
				isOwn = !!desc;

				// By convention, when a data property is converted to an accessor
				// property to emulate a data property that does not suffer from
				// the override mistake, that accessor's getter is marked with
				// an `originalValue` property. Here, when we detect this, we
				// uphold the illusion by pretending to see that original data
				// property, i.e., returning the value rather than the getter
				// itself.
				if (isOwn && 'get' in desc && !('originalValue' in desc.get)) {
					value = desc.get;
				} else {
					value = value[part];
				}
			} else {
				isOwn = hasOwn(value, part);
				value = value[part];
			}

			if (isOwn && !skipFurtherCaching) {
				INTRINSICS[intrinsicRealName] = value;
			}
		}
	}
	return value;
};

},{"function-bind":25,"has":29,"has-symbols":27}],27:[function(require,module,exports){
'use strict';

var origSymbol = typeof Symbol !== 'undefined' && Symbol;
var hasSymbolSham = require('./shams');

module.exports = function hasNativeSymbols() {
	if (typeof origSymbol !== 'function') { return false; }
	if (typeof Symbol !== 'function') { return false; }
	if (typeof origSymbol('foo') !== 'symbol') { return false; }
	if (typeof Symbol('bar') !== 'symbol') { return false; }

	return hasSymbolSham();
};

},{"./shams":28}],28:[function(require,module,exports){
'use strict';

/* eslint complexity: [2, 18], max-statements: [2, 33] */
module.exports = function hasSymbols() {
	if (typeof Symbol !== 'function' || typeof Object.getOwnPropertySymbols !== 'function') { return false; }
	if (typeof Symbol.iterator === 'symbol') { return true; }

	var obj = {};
	var sym = Symbol('test');
	var symObj = Object(sym);
	if (typeof sym === 'string') { return false; }

	if (Object.prototype.toString.call(sym) !== '[object Symbol]') { return false; }
	if (Object.prototype.toString.call(symObj) !== '[object Symbol]') { return false; }

	// temp disabled per https://github.com/ljharb/object.assign/issues/17
	// if (sym instanceof Symbol) { return false; }
	// temp disabled per https://github.com/WebReflection/get-own-property-symbols/issues/4
	// if (!(symObj instanceof Symbol)) { return false; }

	// if (typeof Symbol.prototype.toString !== 'function') { return false; }
	// if (String(sym) !== Symbol.prototype.toString.call(sym)) { return false; }

	var symVal = 42;
	obj[sym] = symVal;
	for (sym in obj) { return false; } // eslint-disable-line no-restricted-syntax, no-unreachable-loop
	if (typeof Object.keys === 'function' && Object.keys(obj).length !== 0) { return false; }

	if (typeof Object.getOwnPropertyNames === 'function' && Object.getOwnPropertyNames(obj).length !== 0) { return false; }

	var syms = Object.getOwnPropertySymbols(obj);
	if (syms.length !== 1 || syms[0] !== sym) { return false; }

	if (!Object.prototype.propertyIsEnumerable.call(obj, sym)) { return false; }

	if (typeof Object.getOwnPropertyDescriptor === 'function') {
		var descriptor = Object.getOwnPropertyDescriptor(obj, sym);
		if (descriptor.value !== symVal || descriptor.enumerable !== true) { return false; }
	}

	return true;
};

},{}],29:[function(require,module,exports){
'use strict';

var bind = require('function-bind');

module.exports = bind.call(Function.call, Object.prototype.hasOwnProperty);

},{"function-bind":25}],30:[function(require,module,exports){
'use strict';

var fnToStr = Function.prototype.toString;
var reflectApply = typeof Reflect === 'object' && Reflect !== null && Reflect.apply;
var badArrayLike;
var isCallableMarker;
if (typeof reflectApply === 'function' && typeof Object.defineProperty === 'function') {
	try {
		badArrayLike = Object.defineProperty({}, 'length', {
			get: function () {
				throw isCallableMarker;
			}
		});
		isCallableMarker = {};
		// eslint-disable-next-line no-throw-literal
		reflectApply(function () { throw 42; }, null, badArrayLike);
	} catch (_) {
		if (_ !== isCallableMarker) {
			reflectApply = null;
		}
	}
} else {
	reflectApply = null;
}

var constructorRegex = /^\s*class\b/;
var isES6ClassFn = function isES6ClassFunction(value) {
	try {
		var fnStr = fnToStr.call(value);
		return constructorRegex.test(fnStr);
	} catch (e) {
		return false; // not a function
	}
};

var tryFunctionObject = function tryFunctionToStr(value) {
	try {
		if (isES6ClassFn(value)) { return false; }
		fnToStr.call(value);
		return true;
	} catch (e) {
		return false;
	}
};
var toStr = Object.prototype.toString;
var fnClass = '[object Function]';
var genClass = '[object GeneratorFunction]';
var hasToStringTag = typeof Symbol === 'function' && !!Symbol.toStringTag; // better: use `has-tostringtag`
/* globals document: false */
var documentDotAll = typeof document === 'object' && typeof document.all === 'undefined' && document.all !== undefined ? document.all : {};

module.exports = reflectApply
	? function isCallable(value) {
		if (value === documentDotAll) { return true; }
		if (!value) { return false; }
		if (typeof value !== 'function' && typeof value !== 'object') { return false; }
		if (typeof value === 'function' && !value.prototype) { return true; }
		try {
			reflectApply(value, null, badArrayLike);
		} catch (e) {
			if (e !== isCallableMarker) { return false; }
		}
		return !isES6ClassFn(value);
	}
	: function isCallable(value) {
		if (value === documentDotAll) { return true; }
		if (!value) { return false; }
		if (typeof value !== 'function' && typeof value !== 'object') { return false; }
		if (typeof value === 'function' && !value.prototype) { return true; }
		if (hasToStringTag) { return tryFunctionObject(value); }
		if (isES6ClassFn(value)) { return false; }
		var strClass = toStr.call(value);
		return strClass === fnClass || strClass === genClass;
	};

},{}],31:[function(require,module,exports){
'use strict';

var keysShim;
if (!Object.keys) {
	// modified from https://github.com/es-shims/es5-shim
	var has = Object.prototype.hasOwnProperty;
	var toStr = Object.prototype.toString;
	var isArgs = require('./isArguments'); // eslint-disable-line global-require
	var isEnumerable = Object.prototype.propertyIsEnumerable;
	var hasDontEnumBug = !isEnumerable.call({ toString: null }, 'toString');
	var hasProtoEnumBug = isEnumerable.call(function () {}, 'prototype');
	var dontEnums = [
		'toString',
		'toLocaleString',
		'valueOf',
		'hasOwnProperty',
		'isPrototypeOf',
		'propertyIsEnumerable',
		'constructor'
	];
	var equalsConstructorPrototype = function (o) {
		var ctor = o.constructor;
		return ctor && ctor.prototype === o;
	};
	var excludedKeys = {
		$applicationCache: true,
		$console: true,
		$external: true,
		$frame: true,
		$frameElement: true,
		$frames: true,
		$innerHeight: true,
		$innerWidth: true,
		$onmozfullscreenchange: true,
		$onmozfullscreenerror: true,
		$outerHeight: true,
		$outerWidth: true,
		$pageXOffset: true,
		$pageYOffset: true,
		$parent: true,
		$scrollLeft: true,
		$scrollTop: true,
		$scrollX: true,
		$scrollY: true,
		$self: true,
		$webkitIndexedDB: true,
		$webkitStorageInfo: true,
		$window: true
	};
	var hasAutomationEqualityBug = (function () {
		/* global window */
		if (typeof window === 'undefined') { return false; }
		for (var k in window) {
			try {
				if (!excludedKeys['$' + k] && has.call(window, k) && window[k] !== null && typeof window[k] === 'object') {
					try {
						equalsConstructorPrototype(window[k]);
					} catch (e) {
						return true;
					}
				}
			} catch (e) {
				return true;
			}
		}
		return false;
	}());
	var equalsConstructorPrototypeIfNotBuggy = function (o) {
		/* global window */
		if (typeof window === 'undefined' || !hasAutomationEqualityBug) {
			return equalsConstructorPrototype(o);
		}
		try {
			return equalsConstructorPrototype(o);
		} catch (e) {
			return false;
		}
	};

	keysShim = function keys(object) {
		var isObject = object !== null && typeof object === 'object';
		var isFunction = toStr.call(object) === '[object Function]';
		var isArguments = isArgs(object);
		var isString = isObject && toStr.call(object) === '[object String]';
		var theKeys = [];

		if (!isObject && !isFunction && !isArguments) {
			throw new TypeError('Object.keys called on a non-object');
		}

		var skipProto = hasProtoEnumBug && isFunction;
		if (isString && object.length > 0 && !has.call(object, 0)) {
			for (var i = 0; i < object.length; ++i) {
				theKeys.push(String(i));
			}
		}

		if (isArguments && object.length > 0) {
			for (var j = 0; j < object.length; ++j) {
				theKeys.push(String(j));
			}
		} else {
			for (var name in object) {
				if (!(skipProto && name === 'prototype') && has.call(object, name)) {
					theKeys.push(String(name));
				}
			}
		}

		if (hasDontEnumBug) {
			var skipConstructor = equalsConstructorPrototypeIfNotBuggy(object);

			for (var k = 0; k < dontEnums.length; ++k) {
				if (!(skipConstructor && dontEnums[k] === 'constructor') && has.call(object, dontEnums[k])) {
					theKeys.push(dontEnums[k]);
				}
			}
		}
		return theKeys;
	};
}
module.exports = keysShim;

},{"./isArguments":33}],32:[function(require,module,exports){
'use strict';

var slice = Array.prototype.slice;
var isArgs = require('./isArguments');

var origKeys = Object.keys;
var keysShim = origKeys ? function keys(o) { return origKeys(o); } : require('./implementation');

var originalKeys = Object.keys;

keysShim.shim = function shimObjectKeys() {
	if (Object.keys) {
		var keysWorksWithArguments = (function () {
			// Safari 5.0 bug
			var args = Object.keys(arguments);
			return args && args.length === arguments.length;
		}(1, 2));
		if (!keysWorksWithArguments) {
			Object.keys = function keys(object) { // eslint-disable-line func-name-matching
				if (isArgs(object)) {
					return originalKeys(slice.call(object));
				}
				return originalKeys(object);
			};
		}
	} else {
		Object.keys = keysShim;
	}
	return Object.keys || keysShim;
};

module.exports = keysShim;

},{"./implementation":31,"./isArguments":33}],33:[function(require,module,exports){
'use strict';

var toStr = Object.prototype.toString;

module.exports = function isArguments(value) {
	var str = toStr.call(value);
	var isArgs = str === '[object Arguments]';
	if (!isArgs) {
		isArgs = str !== '[object Array]' &&
			value !== null &&
			typeof value === 'object' &&
			typeof value.length === 'number' &&
			value.length >= 0 &&
			toStr.call(value.callee) === '[object Function]';
	}
	return isArgs;
};

},{}],34:[function(require,module,exports){
/**
 * @typedef {Object} Options
 *
 * @property {Number} [timeout=0] - Timeout in ms after that promise will be rejected automatically.
 * @property {String|Function} [timeoutReason] - Rejection reason for timeout.
 * Promise will be rejected with {@link PromiseController.TimeoutError} and this message. The message can contain
 * placeholder `{timeout}` for actual timeout value. If timeoutReason is a function,
 * it will be evaluated and returned value will be used as message.
 * @property {String|Function} [resetReason] - Rejection reason used when `.reset()` is called while promise is pending.
 * Promise will be rejected with {@link PromiseController.ResetError} and this message. If resetReason is a function,
 * it will be evaluated and returned value will be used as message.
 */

module.exports = {
  timeout: 0,
  timeoutReason: 'Promise rejected by PromiseController timeout {timeout} ms.',
  resetReason: 'Promise rejected by PromiseController reset.',
};

},{}],35:[function(require,module,exports){
/**
 * @ignore
 */
const defaults = require('./defaults');
const {isPromise, createErrorType, tryCall} = require('./utils');

/**
 * @typicalname pc
 */
class PromiseController {
  /**
   * Creates promise controller. Unlike original Promise, it does not immediately call any function.
   * Instead it has [.call()](#PromiseController+call) method that calls provided function
   * and stores `resolve / reject` methods for future access.
   *
   * @param {Options} [options]
   */
  constructor(options) {
    this._options = Object.assign({}, defaults, options);
    this._resolve = null;
    this._reject = null;
    this._isPending = false;
    this._isFulfilled = false;
    this._isRejected = false;
    this._value = undefined;
    this._promise = null;
    this._timer = null;
  }

  /**
   * Returns promise itself.
   *
   * @returns {Promise}
   */
  get promise() {
    return this._promise;
  }

  /**
   * Returns value with that promise was settled (fulfilled or rejected).
   *
   * @returns {*}
   */
  get value() {
    return this._value;
  }

  /**
   * Returns true if promise is pending.
   *
   * @returns {Boolean}
   */
  get isPending() {
    return this._isPending;
  }

  /**
   * Returns true if promise is fulfilled.
   *
   * @returns {Boolean}
   */
  get isFulfilled() {
    return this._isFulfilled;
  }

  /**
   * Returns true if promise rejected.
   *
   * @returns {Boolean}
   */
  get isRejected() {
    return this._isRejected;
  }

  /**
   * Returns true if promise is fulfilled or rejected.
   *
   * @returns {Boolean}
   */
  get isSettled() {
    return this._isFulfilled || this._isRejected;
  }

  /**
   * Calls `fn` and returns promise OR just returns existing promise from previous `call()` if it is still pending.
   * To fulfill returned promise you should use
   * {@link PromiseController#resolve} / {@link PromiseController#reject} methods.
   * If `fn` itself returns promise, then external promise is attached to it and fulfills together.
   * If no `fn` passed - promiseController is initialized as well.
   *
   * @param {Function} [fn] function to be called.
   * @returns {Promise}
   */
  call(fn) {
    if (!this._isPending) {
      this.reset();
      this._createPromise();
      this._createTimer();
      this._callFn(fn);
    }
    return this._promise;
  }

  /**
   * Resolves pending promise with specified `value`.
   *
   * @param {*} [value]
   */
  resolve(value) {
    if (this._isPending) {
      if (isPromise(value)) {
        this._tryAttachToPromise(value);
      } else {
        this._settle(value);
        this._isFulfilled = true;
        this._resolve(value);
      }
    }
  }

  /**
   * Rejects pending promise with specified `value`.
   *
   * @param {*} [value]
   */
  reject(value) {
    if (this._isPending) {
      this._settle(value);
      this._isRejected = true;
      this._reject(value);
    }
  }

  /**
   * Resets to initial state.
   * If promise is pending it will be rejected with {@link PromiseController.ResetError}.
   */
  reset() {
    if (this._isPending) {
      const message = tryCall(this._options.resetReason);
      const error = new PromiseController.ResetError(message);
      this.reject(error);
    }
    this._promise = null;
    this._isPending = false;
    this._isFulfilled = false;
    this._isRejected = false;
    this._value = undefined;
    this._clearTimer();
  }

  /**
   * Re-assign one or more options.
   *
   * @param {Options} options
   */
  configure(options) {
    Object.assign(this._options, options);
  }

  _createPromise() {
    this._promise = new Promise((resolve, reject) => {
      this._isPending = true;
      this._resolve = resolve;
      this._reject = reject;
    });
  }

  _handleTimeout() {
    const messageTpl = tryCall(this._options.timeoutReason);
    const message = typeof messageTpl === 'string' ? messageTpl.replace('{timeout}', this._options.timeout) : '';
    const error = new PromiseController.TimeoutError(message);
    this.reject(error);
  }

  _createTimer() {
    if (this._options.timeout) {
      this._timer = setTimeout(() => this._handleTimeout(), this._options.timeout);
    }
  }

  _clearTimer() {
    if (this._timer) {
      clearTimeout(this._timer);
      this._timer = null;
    }
  }

  _settle(value) {
    this._isPending = false;
    this._value = value;
    this._clearTimer();
  }

  _callFn(fn) {
    if (typeof fn === 'function') {
      try {
        const result = fn();
        this._tryAttachToPromise(result);
      } catch (e) {
        this.reject(e);
      }
    }
  }

  _tryAttachToPromise(p) {
    if (isPromise(p)) {
      p.then(value => this.resolve(value), e => this.reject(e));
    }
  }
}

/**
 * Error for rejection in case of timeout.
 * @type {PromiseController.TimeoutError}
 */
PromiseController.TimeoutError = createErrorType('TimeoutError');

/**
 * Error for rejection in case of call `.reset()` while promise is pending.
 * @type {PromiseController.ResetError}
 */
PromiseController.ResetError = createErrorType('ResetError');

module.exports = PromiseController;

},{"./defaults":34,"./utils":36}],36:[function(require,module,exports){

/**
 * Simple check for Promise.
 * @param {*} p
 * @returns {Boolean}
 * @ignore
 */
exports.isPromise = function (p) {
  return p && typeof p.then === 'function';
};

/**
 * Calls argument if it is function
 * @param {*} value
 * @returns {*}
 * @ignore
 */
exports.tryCall = function (value) {
  return typeof value === 'function' ? value() : value;
};

/**
 * Just `class MyError extends Error` does not work with transpiler.
 * See: https://stackoverflow.com/questions/1382107/whats-a-good-way-to-extend-error-in-javascript
 * @ignore
 */
exports.createErrorType = function (name) {
  function E(message) {
    if (!Error.captureStackTrace) {
      this.stack = (new Error()).stack;
    } else {
      Error.captureStackTrace(this, this.constructor);
    }
    this.message = message;
  }
  E.prototype = new Error();
  E.prototype.name = name;
  E.prototype.constructor = E;
  return E;
};

},{}],37:[function(require,module,exports){
'use strict';

var requirePromise = require('./requirePromise');

requirePromise();

var IsCallable = require('es-abstract/2021/IsCallable');
var SpeciesConstructor = require('es-abstract/2021/SpeciesConstructor');
var Type = require('es-abstract/2021/Type');

var promiseResolve = function PromiseResolve(C, value) {
	return new C(function (resolve) {
		resolve(value);
	});
};

var OriginalPromise = Promise;

var createThenFinally = function CreateThenFinally(C, onFinally) {
	return function (value) {
		var result = onFinally();
		var promise = promiseResolve(C, result);
		var valueThunk = function () {
			return value;
		};
		return promise.then(valueThunk);
	};
};

var createCatchFinally = function CreateCatchFinally(C, onFinally) {
	return function (reason) {
		var result = onFinally();
		var promise = promiseResolve(C, result);
		var thrower = function () {
			throw reason;
		};
		return promise.then(thrower);
	};
};

var promiseFinally = function finally_(onFinally) {
	/* eslint no-invalid-this: 0 */

	var promise = this;

	if (Type(promise) !== 'Object') {
		throw new TypeError('receiver is not an Object');
	}

	var C = SpeciesConstructor(promise, OriginalPromise); // may throw

	var thenFinally = onFinally;
	var catchFinally = onFinally;
	if (IsCallable(onFinally)) {
		thenFinally = createThenFinally(C, onFinally);
		catchFinally = createCatchFinally(C, onFinally);
	}

	return promise.then(thenFinally, catchFinally);
};

if (Object.getOwnPropertyDescriptor) {
	var descriptor = Object.getOwnPropertyDescriptor(promiseFinally, 'name');
	if (descriptor && descriptor.configurable) {
		Object.defineProperty(promiseFinally, 'name', { configurable: true, value: 'finally' });
	}
}

module.exports = promiseFinally;

},{"./requirePromise":40,"es-abstract/2021/IsCallable":9,"es-abstract/2021/SpeciesConstructor":14,"es-abstract/2021/Type":17}],38:[function(require,module,exports){
'use strict';

var callBind = require('call-bind');
var define = require('define-properties');

var implementation = require('./implementation');
var getPolyfill = require('./polyfill');
var shim = require('./shim');

var bound = callBind(getPolyfill());

define(bound, {
	getPolyfill: getPolyfill,
	implementation: implementation,
	shim: shim
});

module.exports = bound;

},{"./implementation":37,"./polyfill":39,"./shim":41,"call-bind":2,"define-properties":4}],39:[function(require,module,exports){
'use strict';

var requirePromise = require('./requirePromise');

var implementation = require('./implementation');

module.exports = function getPolyfill() {
	requirePromise();
	return typeof Promise.prototype['finally'] === 'function' ? Promise.prototype['finally'] : implementation;
};

},{"./implementation":37,"./requirePromise":40}],40:[function(require,module,exports){
'use strict';

module.exports = function requirePromise() {
	if (typeof Promise !== 'function') {
		throw new TypeError('`Promise.prototype.finally` requires a global `Promise` be available.');
	}
};

},{}],41:[function(require,module,exports){
'use strict';

var requirePromise = require('./requirePromise');

var getPolyfill = require('./polyfill');
var define = require('define-properties');

module.exports = function shimPromiseFinally() {
	requirePromise();

	var polyfill = getPolyfill();
	define(Promise.prototype, { 'finally': polyfill }, {
		'finally': function testFinally() {
			return Promise.prototype['finally'] !== polyfill;
		}
	});
	return polyfill;
};

},{"./polyfill":39,"./requirePromise":40,"define-properties":4}],42:[function(require,module,exports){
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.PromisedMap = void 0;
var PromisedMap = /** @class */ (function () {
    function PromisedMap() {
        this.map = new Map();
    }
    Object.defineProperty(PromisedMap.prototype, "size", {
        /**
         * Returns map size.
         */
        get: function () {
            return this.map.size;
        },
        enumerable: false,
        configurable: true
    });
    /**
     * Sets key/data pair and creates related promise.
     * If key already exists in map - it will be replaced with new data and new promise.
     */
    PromisedMap.prototype.set = function (key, data) {
        var item = this.createMapItem(data);
        this.map.set(key, item);
        return item.promise;
    };
    /**
     * Returns data for key.
     */
    PromisedMap.prototype.get = function (key) {
        var item = this.map.get(key);
        return item && item.data;
    };
    /**
     * Checks if key exists.
     */
    PromisedMap.prototype.has = function (key) {
        return this.map.has(key);
    };
    /**
     * Deletes key from map.
     * Caution: previously returned promise will no be resolved or rejected.
     */
    PromisedMap.prototype.delete = function (key) {
        return this.map.delete(key);
    };
    /**
     * Resolves promise in map by key and removes key from map.
     * If no such key in map - nothing happens.
     */
    PromisedMap.prototype.resolve = function (key, value) {
        var item = this.map.get(key);
        if (item) {
            this.delete(key);
            item.resolve(value);
        }
    };
    /**
     * Rejects promise in map by key and removes key from map.
     * If no such key in map - nothing happens.
     */
    PromisedMap.prototype.reject = function (key, reason) {
        var item = this.map.get(key);
        if (item) {
            this.delete(key);
            item.reject(reason);
        }
    };
    /**
     * Resolves all promise in map and removes all keys.
     */
    PromisedMap.prototype.resolveAll = function (value) {
        this.map.forEach(function (item) { return item.resolve(value); });
        this.map.clear();
    };
    /**
     * Rejects all promise in map and removes all keys.
     */
    PromisedMap.prototype.rejectAll = function (reason) {
        this.map.forEach(function (item) { return item.reject(reason); });
        this.map.clear();
    };
    /**
     * Iterate map.
     */
    PromisedMap.prototype.forEach = function (fn) {
        this.map.forEach(function (item, key, map) { return fn(item.data, key, map); });
    };
    /**
     * Clears map.
     */
    PromisedMap.prototype.clear = function () {
        return this.map.clear();
    };
    PromisedMap.prototype.createMapItem = function (data) {
        var item = { data: data };
        item.promise = new Promise(function (resolve, reject) {
            item.resolve = resolve;
            item.reject = reject;
        });
        return item;
    };
    return PromisedMap;
}());
exports.PromisedMap = PromisedMap;

},{}],43:[function(require,module,exports){
/**
 * Default options.
 */

/**
 * @typedef {Object} Options
 * @property {Function} [createWebSocket=url => new WebSocket(url)] - custom function for WebSocket construction.
  *
 * @property {Function} [packMessage=noop] - packs message for sending. For example, `data => JSON.stringify(data)`.
 *
 * @property {Function} [unpackMessage=noop] - unpacks received message. For example, `data => JSON.parse(data)`.
 *
 * @property {Function} [attachRequestId=noop] - injects request id into data.
 * For example, `(data, requestId) => Object.assign({requestId}, data)`.
 *
 * @property {Function} [extractRequestId=noop] - extracts request id from received data.
 * For example, `data => data.requestId`.
 *
 * @property {Function} [extractMessageData=event => event.data] - extracts data from event object.
 *
 * @property {Number} timeout=0 - timeout for opening connection and sending messages.
 *
 * @property {Number} connectionTimeout=0 - special timeout for opening connection, by default equals to `timeout`.
 *
 * @defaults
 * please see [options.js](https://github.com/vitalets/websocket-as-promised/blob/master/src/options.js)
 */

module.exports = {
  /**
   * See {@link Options.createWebSocket}
   *
   * @param {String} url
   * @returns {WebSocket}
   */
  createWebSocket: url => new WebSocket(url),

  /**
   * See {@link Options.packMessage}
   *
   * @param {*} data
   * @returns {String|ArrayBuffer|Blob}
   */
  packMessage: null,

  /**
   * See {@link Options.unpackMessage}
   *
   * @param {String|ArrayBuffer|Blob} data
   * @returns {*}
   */
  unpackMessage: null,

  /**
   * See {@link Options.attachRequestId}
   *
   * @param {*} data
   * @param {String|Number} requestId
   * @returns {*}
   */
  attachRequestId: null,

  /**
   * See {@link Options.extractRequestId}
   *
   * @param {*} data
   * @returns {String|Number|undefined}
   */
  extractRequestId: null,

  /**
   * See {@link Options.extractMessageData}
   *
   * @param {*} event
   * @returns {*}
   */
  extractMessageData: event => event.data,

  /**
   * See {@link Options.timeout}
   */
  timeout: 0,

  /**
   * See {@link Options.connectionTimeout}
   */
  connectionTimeout: 0,
};

},{}],44:[function(require,module,exports){
/**
 * Class for manage pending requests.
 * @private
 */

const PromiseController = require('promise-controller');
const promiseFinally = require('promise.prototype.finally');

module.exports = class Requests {
  constructor() {
    this._items = new Map();
  }

  /**
   * Creates new request and stores it in the list.
   *
   * @param {String|Number} requestId
   * @param {Function} fn
   * @param {Number} timeout
   * @returns {Promise}
   */
  create(requestId, fn, timeout) {
    this._rejectExistingRequest(requestId);
    return this._createNewRequest(requestId, fn, timeout);
  }

  resolve(requestId, data) {
    if (requestId && this._items.has(requestId)) {
      this._items.get(requestId).resolve(data);
    }
  }

  rejectAll(error) {
    this._items.forEach(request => request.isPending ? request.reject(error) : null);
  }

  _rejectExistingRequest(requestId) {
    const existingRequest = this._items.get(requestId);
    if (existingRequest && existingRequest.isPending) {
      existingRequest.reject(new Error(`WebSocket request is replaced, id: ${requestId}`));
    }
  }

  _createNewRequest(requestId, fn, timeout) {
    const request = new PromiseController({
      timeout,
      timeoutReason: `WebSocket request was rejected by timeout (${timeout} ms). RequestId: ${requestId}`
    });
    this._items.set(requestId, request);
    return promiseFinally(request.call(fn), () => this._deleteRequest(requestId, request));
  }

  _deleteRequest(requestId, request) {
    // this check is important when request was replaced
    if (this._items.get(requestId) === request) {
      this._items.delete(requestId);
    }
  }
};

},{"promise-controller":35,"promise.prototype.finally":38}],45:[function(require,module,exports){

exports.throwIf = (condition, message) => {
  if (condition) {
    throw new Error(message);
  }
};

exports.isPromise = value => {
  return value && typeof value.then === 'function';
};

},{}],"websocket-as-promised":[function(require,module,exports){
/**
 * WebSocket with promise api
 */

/**
 * @external Channel
 */

const Channel = require('chnl');
// todo: maybe remove PromiseController and just use promised-map with 2 items?
const PromiseController = require('promise-controller');
const { PromisedMap } = require('promised-map');
// todo: maybe remove Requests and just use promised-map?
const Requests = require('./requests');
const defaultOptions = require('./options');
const {throwIf, isPromise} = require('./utils');

// see: https://developer.mozilla.org/en-US/docs/Web/API/WebSocket#Ready_state_constants
const STATE = {
  CONNECTING: 0,
  OPEN: 1,
  CLOSING: 2,
  CLOSED: 3,
};

/**
 * @typicalname wsp
 */
class WebSocketAsPromised {
  /**
   * Constructor. Unlike original WebSocket it does not immediately open connection.
   * Please call `open()` method to connect.
   *
   * @param {String} url WebSocket URL
   * @param {Options} [options]
   */
  constructor(url, options) {
    this._assertOptions(options);
    this._url = url;
    this._options = Object.assign({}, defaultOptions, options);
    this._requests = new Requests();
    this._promisedMap = new PromisedMap();
    this._ws = null;
    this._wsSubscription = null;
    this._createOpeningController();
    this._createClosingController();
    this._createChannels();
  }

  /**
   * Returns original WebSocket instance created by `options.createWebSocket`.
   *
   * @returns {WebSocket}
   */
  get ws() {
    return this._ws;
  }

  /**
   * Returns WebSocket url.
   *
   * @returns {String}
   */
  get url() {
    return this._url;
  }

  /**
   * Is WebSocket connection in opening state.
   *
   * @returns {Boolean}
   */
  get isOpening() {
    return Boolean(this._ws && this._ws.readyState === STATE.CONNECTING);
  }

  /**
   * Is WebSocket connection opened.
   *
   * @returns {Boolean}
   */
  get isOpened() {
    return Boolean(this._ws && this._ws.readyState === STATE.OPEN);
  }

  /**
   * Is WebSocket connection in closing state.
   *
   * @returns {Boolean}
   */
  get isClosing() {
    return Boolean(this._ws && this._ws.readyState === STATE.CLOSING);
  }

  /**
   * Is WebSocket connection closed.
   *
   * @returns {Boolean}
   */
  get isClosed() {
    return Boolean(!this._ws || this._ws.readyState === STATE.CLOSED);
  }

  /**
   * Event channel triggered when connection is opened.
   *
   * @see https://vitalets.github.io/chnl/#channel
   * @example
   * wsp.onOpen.addListener(() => console.log('Connection opened'));
   *
   * @returns {Channel}
   */
  get onOpen() {
    return this._onOpen;
  }

  /**
   * Event channel triggered every time when message is sent to server.
   *
   * @see https://vitalets.github.io/chnl/#channel
   * @example
   * wsp.onSend.addListener(data => console.log('Message sent', data));
   *
   * @returns {Channel}
   */
  get onSend() {
    return this._onSend;
  }

  /**
   * Event channel triggered every time when message received from server.
   *
   * @see https://vitalets.github.io/chnl/#channel
   * @example
   * wsp.onMessage.addListener(message => console.log(message));
   *
   * @returns {Channel}
   */
  get onMessage() {
    return this._onMessage;
  }

  /**
   * Event channel triggered every time when received message is successfully unpacked.
   * For example, if you are using JSON transport, the listener will receive already JSON parsed data.
   *
   * @see https://vitalets.github.io/chnl/#channel
   * @example
   * wsp.onUnpackedMessage.addListener(data => console.log(data.foo));
   *
   * @returns {Channel}
   */
  get onUnpackedMessage() {
    return this._onUnpackedMessage;
  }

  /**
   * Event channel triggered every time when response to some request comes.
   * Received message considered a response if requestId is found in it.
   *
   * @see https://vitalets.github.io/chnl/#channel
   * @example
   * wsp.onResponse.addListener(data => console.log(data));
   *
   * @returns {Channel}
   */
  get onResponse() {
    return this._onResponse;
  }

  /**
   * Event channel triggered when connection closed.
   * Listener accepts single argument `{code, reason}`.
   *
   * @see https://vitalets.github.io/chnl/#channel
   * @example
   * wsp.onClose.addListener(event => console.log(`Connections closed: ${event.reason}`));
   *
   * @returns {Channel}
   */
  get onClose() {
    return this._onClose;
  }

  /**
   * Event channel triggered when by Websocket 'error' event.
   *
   * @see https://vitalets.github.io/chnl/#channel
   * @example
   * wsp.onError.addListener(event => console.error(event));
   *
   * @returns {Channel}
   */
  get onError() {
    return this._onError;
  }

  /**
   * Opens WebSocket connection. If connection already opened, promise will be resolved with "open event".
   *
   * @returns {Promise<Event>}
   */
  open() {
    if (this.isClosing) {
      return Promise.reject(new Error(`Can't open WebSocket while closing.`));
    }
    if (this.isOpened) {
      return this._opening.promise;
    }
    return this._opening.call(() => {
      this._opening.promise.catch(e => this._cleanup(e));
      this._createWS();
    });
  }

  /**
   * Performs request and waits for response.
   *
   * @param {*} data
   * @param {Object} [options]
   * @param {String|Number} [options.requestId=<auto-generated>]
   * @param {Number} [options.timeout=0]
   * @returns {Promise}
   */
  sendRequest(data, options = {}) {
    const requestId = options.requestId || `${Math.random()}`;
    const timeout = options.timeout !== undefined ? options.timeout : this._options.timeout;
    return this._requests.create(requestId, () => {
      this._assertRequestIdHandlers();
      const finalData = this._options.attachRequestId(data, requestId);
      this.sendPacked(finalData);
    }, timeout);
  }

  /**
   * Packs data with `options.packMessage` and sends to the server.
   *
   * @param {*} data
   */
  sendPacked(data) {
    this._assertPackingHandlers();
    const message = this._options.packMessage(data);
    this.send(message);
  }

  /**
   * Sends data without packing.
   *
   * @param {String|Blob|ArrayBuffer} data
   */
  send(data) {
    throwIf(!this.isOpened, `Can't send data because WebSocket is not opened.`);
    this._ws.send(data);
    this._onSend.dispatchAsync(data);
  }

  /**
   * Waits for particular message to come.
   *
   * @param {Function} predicate function to check incoming message.
   * @param {Object} [options]
   * @param {Number} [options.timeout=0]
   * @param {Error} [options.timeoutError]
   * @returns {Promise}
   *
   * @example
   * const response = await wsp.waitUnpackedMessage(data => data && data.foo === 'bar');
   */
  waitUnpackedMessage(predicate, options = {}) {
    throwIf(typeof predicate !== 'function', `Predicate must be a function, got ${typeof predicate}`);
    if (options.timeout) {
      setTimeout(() => {
        if (this._promisedMap.has(predicate)) {
          const error = options.timeoutError || new Error('Timeout');
          this._promisedMap.reject(predicate, error);
        }
      }, options.timeout);
    }
    return this._promisedMap.set(predicate);
  }

  /**
   * Closes WebSocket connection. If connection already closed, promise will be resolved with "close event".
   *
   * @param {number=} [code=1000] A numeric value indicating the status code.
   * @param {string=} [reason] A human-readable reason for closing connection.
   * @returns {Promise<Event>}
   */
  close(code, reason) { // https://developer.mozilla.org/en-US/docs/Web/API/WebSocket/close
    return this.isClosed
      ? Promise.resolve(this._closing.value)
      : this._closing.call(() => this._ws.close(code, reason));
  }

  /**
   * Removes all listeners from WSP instance. Useful for cleanup.
   */
  removeAllListeners() {
    this._onOpen.removeAllListeners();
    this._onMessage.removeAllListeners();
    this._onUnpackedMessage.removeAllListeners();
    this._onResponse.removeAllListeners();
    this._onSend.removeAllListeners();
    this._onClose.removeAllListeners();
    this._onError.removeAllListeners();
  }

  _createOpeningController() {
    const connectionTimeout = this._options.connectionTimeout || this._options.timeout;
    this._opening = new PromiseController({
      timeout: connectionTimeout,
      timeoutReason: `Can't open WebSocket within allowed timeout: ${connectionTimeout} ms.`
    });
  }

  _createClosingController() {
    const closingTimeout = this._options.timeout;
    this._closing = new PromiseController({
      timeout: closingTimeout,
      timeoutReason: `Can't close WebSocket within allowed timeout: ${closingTimeout} ms.`
    });
  }

  _createChannels() {
    this._onOpen = new Channel();
    this._onMessage = new Channel();
    this._onUnpackedMessage = new Channel();
    this._onResponse = new Channel();
    this._onSend = new Channel();
    this._onClose = new Channel();
    this._onError = new Channel();
  }

  _createWS() {
    this._ws = this._options.createWebSocket(this._url);
    this._wsSubscription = new Channel.Subscription([
      { channel: this._ws, event: 'open', listener: e => this._handleOpen(e) },
      { channel: this._ws, event: 'message', listener: e => this._handleMessage(e) },
      { channel: this._ws, event: 'error', listener: e => this._handleError(e) },
      { channel: this._ws, event: 'close', listener: e => this._handleClose(e) },
    ]).on();
  }

  _handleOpen(event) {
    this._onOpen.dispatchAsync(event);
    this._opening.resolve(event);
  }

  _handleMessage(event) {
    const data = this._options.extractMessageData(event);
    this._onMessage.dispatchAsync(data);
    this._tryUnpack(data);
  }

  _tryUnpack(data) {
    if (this._options.unpackMessage) {
      data = this._options.unpackMessage(data);
      if (isPromise(data)) {
        data.then(data => this._handleUnpackedData(data));
      } else {
        this._handleUnpackedData(data);
      }
    }
  }

  _handleUnpackedData(data) {
    if (data !== undefined) {
      // todo: maybe trigger onUnpackedMessage always?
      this._onUnpackedMessage.dispatchAsync(data);
      this._tryHandleResponse(data);
    }
    this._tryHandleWaitingMessage(data);
  }

  _tryHandleResponse(data) {
    if (this._options.extractRequestId) {
      const requestId = this._options.extractRequestId(data);
      if (requestId) {
        this._onResponse.dispatchAsync(data, requestId);
        this._requests.resolve(requestId, data);
      }
    }
  }

  _tryHandleWaitingMessage(data) {
    this._promisedMap.forEach((_, predicate) => {
      let isMatched = false;
      try {
        isMatched = predicate(data);
      } catch (e) {
        this._promisedMap.reject(predicate, e);
        return;
      }
      if (isMatched) {
        this._promisedMap.resolve(predicate, data);
      }
    });
  }

  _handleError(event) {
    this._onError.dispatchAsync(event);
  }

  _handleClose(event) {
    this._onClose.dispatchAsync(event);
    this._closing.resolve(event);
    const error = new Error(`WebSocket closed with reason: ${event.reason} (${event.code}).`);
    if (this._opening.isPending) {
      this._opening.reject(error);
    }
    this._cleanup(error);
  }

  _cleanupWS() {
    if (this._wsSubscription) {
      this._wsSubscription.off();
      this._wsSubscription = null;
    }
    this._ws = null;
  }

  _cleanup(error) {
    this._cleanupWS();
    this._requests.rejectAll(error);
  }

  _assertOptions(options) {
    Object.keys(options || {}).forEach(key => {
      if (!defaultOptions.hasOwnProperty(key)) {
        throw new Error(`Unknown option: ${key}`);
      }
    });
  }

  _assertPackingHandlers() {
    const { packMessage, unpackMessage } = this._options;
    throwIf(!packMessage || !unpackMessage,
      `Please define 'options.packMessage / options.unpackMessage' for sending packed messages.`
    );
  }

  _assertRequestIdHandlers() {
    const { attachRequestId, extractRequestId } = this._options;
    throwIf(!attachRequestId || !extractRequestId,
      `Please define 'options.attachRequestId / options.extractRequestId' for sending requests.`
    );
  }
}

module.exports = WebSocketAsPromised;

},{"./options":43,"./requests":44,"./utils":45,"chnl":3,"promise-controller":35,"promised-map":42}]},{},[]);
