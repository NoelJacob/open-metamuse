import { error, type RequestHandler } from '@sveltejs/kit';

export const GET: RequestHandler = ({ url }) => {
	const email = url.searchParams.get("email");

	if (!email) {
		error(400, 'Email is required');
	}
	// TODO send mail

	return new Response(null, {status: 200});
};
