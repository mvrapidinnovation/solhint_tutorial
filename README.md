### Solhint Demo

Solhint is a tool that provides rules for security checking and also validates compliance with the style guide and best practices.

To get started with solhint:

```shell
npm install -g solhint

solhint contracts/**/*.sol
```

To create a configuration file:

```shell
solhint init-config
```

This will create a _.solhint.json_ file, which is a Solhint's configuration file in which we can specify what rules in a key value pair. We can get the **solhint rules guide** [here](https://github.com/protofire/solhint/blob/master/docs/rules.md).

Each rule is defined as a key-value pair in the "rules" object in the configuration file. The rules have a level of severity which can be given as follows:

```
{
  "rules": {
    "func-name-mixedcase": "warn"
  }
}
```

This rule will warn about not having mixed case function name. Each rule can have the severity of "error", "warn", "off". With the value of "off" for the severity we can make exception for the rule.

We can also configure the solhint with the inline comments:

-- To disable solhint to lint the next line.

```
// solhint-disable-next-line
```

-- To disable a specific rule on next line.

- This will disable the rule for naming function in mixed case for the next line.

```
// solhint-disable-next-line func-name-mixedcase
```

-- To disable validation on current line.

```
// solhint-disable-line
```

-- To disable specific rules on current line.

- This will disable the rule for naming function in mixed case for the current line.

```
// solhint-disable-line func-name-mixedcase
```

-- To disable rules for set of lines.

```
/* solhint-disable */
  function transferTo(address to, uint amount) public {
    require(tx.origin == owner);
    to.call.value(amount)();
  }
/* solhint-enable */
```

-- To disable specific rule for set of lines.

```
/* solhint-disable avoid-tx-origin */
  function transferTo(address to, uint amount) public {
    require(tx.origin == owner);
    to.call.value(amount)();
  }
/* solhint-enable avoid-tx-origin */
```
