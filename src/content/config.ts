import { defineCollection, z } from 'astro:content';

const worksCollection = defineCollection({
  type: 'content',
  schema: z.object({
    title: z.string(),
    client: z.string(),
    industry: z.string().optional(),
    location: z.string().optional(),
    employees: z.string().optional(),
    phase: z.array(z.string()).optional(),
    tools: z.array(z.string()).optional(),
    summary: z.string().optional(),
    heroImage: z.string().optional(),
  }),
});

const newsCollection = defineCollection({
  type: 'content',
  schema: z.object({
    title: z.string(),
    date: z.string(),
    tags: z.array(z.string()).optional(),
    summary: z.string().optional(),
  }),
});

export const collections = {
  works: worksCollection,
  news: newsCollection,
};
