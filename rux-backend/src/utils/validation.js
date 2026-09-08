const formatValidationError = (error) =>
    error.details
        .map((detail) => detail.message.replace(/"/g, ''))
        .join(', ');

const validateInput = (schema, payload) => {
    const { error, value } = schema.validate(payload, {
        abortEarly: false,
        stripUnknown: true
    });

    if (!error) {
        return { value };
    }

    return { error: formatValidationError(error) };
};

module.exports = { validateInput };
