//
//  MockPoseData.swift
//  test_yoga_ios
//
//  Created by Chang Liu on 1/12/26.
//

import Foundation

struct MockPoseData {
    static let poses: [Pose] = [
        Pose(
            id: "mountain",
            nameEnglish: "Mountain Pose",
            nameSanskrit: "Tadasana",
            description: "The foundation of all standing poses. Stand tall with feet together or hip-width apart, arms at sides. Ground through all four corners of your feet, engage your thighs, and lengthen your spine. This pose improves posture and body awareness.",
            exampleCues: [
                "Ground down through all four corners of your feet",
                "Engage your thighs and lift your kneecaps",
                "Lengthen your tailbone toward the floor",
                "Roll your shoulders back and down",
                "Reach the crown of your head toward the ceiling"
            ],
            benefits: [
                "Improves posture",
                "Strengthens thighs, knees, and ankles",
                "Increases awareness and steadiness",
                "Reduces flat feet"
            ],
            imageURL: "figure.stand",
            category: .standing,
            difficulty: .beginner
        ),
        Pose(
            id: "downward-dog",
            nameEnglish: "Downward-Facing Dog",
            nameSanskrit: "Adho Mukha Svanasana",
            description: "An essential yoga pose that stretches the entire back body. Start on hands and knees, tuck toes, and lift hips up and back. Create an inverted V-shape with your body, pressing hands firmly into the mat.",
            exampleCues: [
                "Spread your fingers wide and press through your knuckles",
                "Rotate your upper arms outward",
                "Draw your shoulder blades down your back",
                "Lift your sit bones toward the ceiling",
                "Pedal your feet to warm up your hamstrings"
            ],
            benefits: [
                "Stretches shoulders, hamstrings, calves, and hands",
                "Strengthens arms and legs",
                "Calms the brain and helps relieve stress",
                "Energizes the body"
            ],
            imageURL: "figure.cooldown",
            category: .inversion,
            difficulty: .beginner
        ),
        Pose(
            id: "warrior-1",
            nameEnglish: "Warrior I",
            nameSanskrit: "Virabhadrasana I",
            description: "A powerful standing pose that builds strength and stability. Step one foot back, bend your front knee, and reach arms overhead. Keep your hips squared forward and back heel grounded.",
            exampleCues: [
                "Ground through your back heel at a 45-degree angle",
                "Bend your front knee directly over your ankle",
                "Square your hips toward the front of the mat",
                "Reach your arms overhead, palms facing each other",
                "Draw your tailbone down and lift your chest"
            ],
            benefits: [
                "Strengthens legs, back, and arms",
                "Stretches chest, lungs, and shoulders",
                "Improves focus and balance",
                "Builds stamina and endurance"
            ],
            imageURL: "figure.arms.open",
            category: .standing,
            difficulty: .beginner
        ),
        Pose(
            id: "warrior-2",
            nameEnglish: "Warrior II",
            nameSanskrit: "Virabhadrasana II",
            description: "A strong standing pose with arms extended parallel to the floor. Feet are wide apart, front knee bent, back leg straight. Gaze over your front fingertips while keeping your torso centered.",
            exampleCues: [
                "Align your front heel with your back arch",
                "Bend your front knee to 90 degrees",
                "Extend your arms parallel to the floor",
                "Keep your torso directly over your pelvis",
                "Gaze softly over your front fingertips"
            ],
            benefits: [
                "Strengthens legs and ankles",
                "Stretches groins, chest, and shoulders",
                "Increases stamina",
                "Relieves backaches"
            ],
            imageURL: "figure.walk",
            category: .standing,
            difficulty: .beginner
        ),
        Pose(
            id: "tree",
            nameEnglish: "Tree Pose",
            nameSanskrit: "Vrksasana",
            description: "A balancing pose that develops concentration and stability. Stand on one leg and place the sole of your other foot on your inner thigh or calf (avoid the knee). Bring hands to heart center or reach overhead.",
            exampleCues: [
                "Root down through your standing foot",
                "Press your foot and thigh into each other",
                "Engage your core for stability",
                "Find a focal point to help with balance",
                "Grow tall through the crown of your head"
            ],
            benefits: [
                "Improves balance and stability",
                "Strengthens thighs, calves, and ankles",
                "Stretches groins and inner thighs",
                "Calms and focuses the mind"
            ],
            imageURL: "figure.yoga",
            category: .balance,
            difficulty: .beginner
        ),
        Pose(
            id: "triangle",
            nameEnglish: "Triangle Pose",
            nameSanskrit: "Trikonasana",
            description: "A standing pose that creates a triangle shape with the body. With wide legs, extend your torso over your front leg, reaching one hand to your shin or the floor while the other arm extends upward.",
            exampleCues: [
                "Keep both legs straight and strong",
                "Hinge at your hip, not your waist",
                "Stack your shoulders and extend through both arms",
                "Rotate your chest toward the ceiling",
                "Keep your neck long and gaze upward or forward"
            ],
            benefits: [
                "Stretches legs, hips, and spine",
                "Opens chest and shoulders",
                "Strengthens thighs, knees, and ankles",
                "Stimulates abdominal organs"
            ],
            imageURL: "figure.flexibility",
            category: .standing,
            difficulty: .intermediate
        ),
        Pose(
            id: "childs-pose",
            nameEnglish: "Child's Pose",
            nameSanskrit: "Balasana",
            description: "A restful pose that gently stretches the back. Kneel on the floor, sit back on your heels, and fold forward with arms extended or alongside your body. Rest your forehead on the mat.",
            exampleCues: [
                "Bring your big toes together and separate your knees",
                "Sink your hips back toward your heels",
                "Walk your hands forward to lengthen your spine",
                "Rest your forehead on the mat",
                "Breathe deeply into your back body"
            ],
            benefits: [
                "Gently stretches hips, thighs, and ankles",
                "Calms the brain and relieves stress",
                "Relieves back and neck pain",
                "Provides a resting position during practice"
            ],
            imageURL: "figure.mind.and.body",
            category: .seated,
            difficulty: .beginner
        ),
        Pose(
            id: "cobra",
            nameEnglish: "Cobra Pose",
            nameSanskrit: "Bhujangasana",
            description: "A gentle backbend that strengthens the spine. Lie face down, place hands under shoulders, and lift your chest while keeping your pelvis grounded. Use your back muscles more than arm strength.",
            exampleCues: [
                "Press the tops of your feet into the mat",
                "Engage your legs and firm your glutes slightly",
                "Place your hands under your shoulders",
                "Lift your chest using your back muscles",
                "Keep your elbows close to your body"
            ],
            benefits: [
                "Strengthens the spine",
                "Stretches chest, shoulders, and abdomen",
                "Opens the heart and lungs",
                "Helps relieve stress and fatigue"
            ],
            imageURL: "figure.strengthening.functional",
            category: .prone,
            difficulty: .beginner
        ),
        Pose(
            id: "pigeon",
            nameEnglish: "Pigeon Pose",
            nameSanskrit: "Eka Pada Rajakapotasana",
            description: "A deep hip opener that targets the outer hip and hip flexor. From all fours, bring one knee forward and extend the back leg behind you. Keep your hips square and fold forward for a deeper stretch.",
            exampleCues: [
                "Bring your front shin as parallel to the mat as comfortable",
                "Square your hips toward the front",
                "Keep your back leg extended straight behind you",
                "Walk your hands forward to deepen the stretch",
                "Breathe into any areas of tightness"
            ],
            benefits: [
                "Stretches hip flexors and rotators",
                "Opens the groin and hip flexors",
                "Releases stored tension and emotions",
                "Prepares the body for seated postures"
            ],
            imageURL: "figure.pilates",
            category: .hipOpener,
            difficulty: .intermediate
        ),
        Pose(
            id: "corpse",
            nameEnglish: "Corpse Pose",
            nameSanskrit: "Savasana",
            description: "The final relaxation pose. Lie on your back with legs extended and arms at your sides, palms facing up. Close your eyes and allow your whole body to relax completely.",
            exampleCues: [
                "Lie flat on your back with legs extended",
                "Let your feet fall open naturally",
                "Rest your arms alongside your body, palms up",
                "Close your eyes and relax your face",
                "Release all effort and let go completely"
            ],
            benefits: [
                "Calms the nervous system",
                "Reduces blood pressure and anxiety",
                "Promotes deep relaxation",
                "Allows the body to integrate the practice"
            ],
            imageURL: "bed.double",
            category: .supine,
            difficulty: .beginner
        ),
        Pose(
            id: "cat-cow",
            nameEnglish: "Cat-Cow Stretch",
            nameSanskrit: "Marjaryasana-Bitilasana",
            description: "A gentle flow between two poses that warms up the spine. On hands and knees, alternate between arching your back (cow) and rounding your spine (cat), moving with your breath.",
            exampleCues: [
                "Start on hands and knees in tabletop position",
                "Inhale, drop your belly and lift your gaze (cow)",
                "Exhale, round your spine and tuck your chin (cat)",
                "Move slowly with your breath",
                "Keep your shoulders over your wrists"
            ],
            benefits: [
                "Warms up the spine",
                "Improves posture and balance",
                "Strengthens and stretches the neck and torso",
                "Massages internal organs"
            ],
            imageURL: "figure.wave",
            category: .allFours,
            difficulty: .beginner
        ),
        Pose(
            id: "bridge",
            nameEnglish: "Bridge Pose",
            nameSanskrit: "Setu Bandhasana",
            description: "A gentle backbend that opens the chest and strengthens the legs. Lie on your back with knees bent, feet flat on the floor. Lift your hips toward the ceiling while pressing through your feet.",
            exampleCues: [
                "Place your feet hip-width apart, heels close to your sit bones",
                "Press firmly through your feet to lift your hips",
                "Roll your shoulders underneath you",
                "Interlace your hands under your back if comfortable",
                "Keep your thighs parallel and knees over ankles"
            ],
            benefits: [
                "Stretches chest, neck, and spine",
                "Strengthens back, glutes, and hamstrings",
                "Calms the brain and reduces anxiety",
                "Improves digestion"
            ],
            imageURL: "figure.core.training",
            category: .supine,
            difficulty: .beginner
        )
    ]
}
