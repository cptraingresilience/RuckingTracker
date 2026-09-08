const test = require('node:test');
const assert = require('node:assert/strict');
const Joi = require('joi');
const { validateInput } = require('../src/utils/validation');

test('validateInput strips unknown keys from payload', () => {
    const schema = Joi.object({
        email: Joi.string().email({ tlds: { allow: false } }).required()
    });

    const result = validateInput(schema, {
        email: 'user@example.com',
        role: 'admin'
    });

    assert.equal(result.error, undefined);
    assert.deepEqual(result.value, { email: 'user@example.com' });
});

test('validateInput returns readable error messages', () => {
    const schema = Joi.object({
        period: Joi.string().valid('weekly', 'monthly', 'all').required()
    });

    const result = validateInput(schema, { period: 'yearly' });
    assert.equal(result.value, undefined);
    assert.match(result.error, /period must be one of/);
});
