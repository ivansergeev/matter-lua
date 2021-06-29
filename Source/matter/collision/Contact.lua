--[[
* The `Matter.Contact` module contains methods for creating and manipulating collision contacts.
*
* @class Contact
]]--

Contact = {}
Contact.__index = Contact

--[[
 * Creates a new contact.
 * @method create
 * @param {vertex} vertex
 * @return {contact} A new contact
 ]]--

function Contact.create(vertex)

	-- print('Contact.create')

	return {
		id = Contact.id(vertex),
		vertex = vertex,
		normalImpulse = 0,
		tangentImpulse = 0
	}
end

--[[
 * Generates a contact id.
 * @method id
 * @param {vertex} vertex
 * @return {string} Unique contactID
 ]]--

function Contact.id(vertex)
	return vertex.body.id .. '_' .. vertex.index
end

