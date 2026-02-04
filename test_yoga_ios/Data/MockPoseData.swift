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
            description: "The foundation of all standing poses. Stand tall with feet together or hip-width apart, arms at sides.",
            benefit: "Improves posture, strengthens thighs, knees, and ankles, increases awareness and steadiness",
            sampleCues: [
                "Ground down through all four corners of your feet",
                "Engage your thighs and lift your kneecaps",
                "Lengthen your tailbone toward the floor"
            ],
            mechanics: PoseMechanics(alignmentPrinciple: "Stand with weight evenly distributed", commonCorrection: "Avoid locking knees", keyEngagement: "Core and thighs engaged"),
            muscleGroup: "Legs, Core, Back",
            variations: ["Arms overhead", "Eyes closed for balance challenge"],
            imageURL: "figure.stand",
            category: .standing,
            difficulty: .beginner
        ),
        Pose(
            id: "downward-dog",
            nameEnglish: "Downward-Facing Dog",
            nameSanskrit: "Adho Mukha Svanasana",
            description: "An essential yoga pose that stretches the entire back body.",
            benefit: "Stretches shoulders, hamstrings, calves, and hands. Strengthens arms and legs. Calms the brain.",
            sampleCues: [
                "Spread your fingers wide and press through your knuckles",
                "Lift your sit bones toward the ceiling",
                "Pedal your feet to warm up your hamstrings"
            ],
            mechanics: PoseMechanics(alignmentPrinciple: "Inverted V-shape with hands and feet grounded", commonCorrection: "Don't round the spine", keyEngagement: "Arms and shoulders"),
            muscleGroup: "Shoulders, Hamstrings, Calves, Arms",
            variations: ["Three-legged dog", "Bent knee variation"],
            imageURL: "figure.cooldown",
            category: .inversion,
            difficulty: .beginner
        ),
        Pose(
            id: "warrior-1",
            nameEnglish: "Warrior I",
            nameSanskrit: "Virabhadrasana I",
            description: "A powerful standing pose that builds strength and stability.",
            benefit: "Strengthens legs, back, and arms. Stretches chest, lungs, and shoulders. Improves focus and balance.",
            sampleCues: [
                "Ground through your back heel at a 45-degree angle",
                "Bend your front knee directly over your ankle",
                "Square your hips toward the front of the mat"
            ],
            mechanics: PoseMechanics(alignmentPrinciple: "Lunging stance with arms overhead", commonCorrection: "Keep back heel grounded", keyEngagement: "Quadriceps and glutes"),
            muscleGroup: "Quadriceps, Glutes, Shoulders",
            variations: ["Humble warrior", "Crescent lunge variation"],
            imageURL: "figure.arms.open",
            category: .standing,
            difficulty: .beginner
        ),
        Pose(
            id: "tree",
            nameEnglish: "Tree Pose",
            nameSanskrit: "Vrksasana",
            description: "A balancing pose that develops concentration and stability.",
            benefit: "Improves balance and stability. Strengthens thighs, calves, and ankles. Calms and focuses the mind.",
            sampleCues: [
                "Root down through your standing foot",
                "Press your foot and thigh into each other",
                "Find a focal point to help with balance"
            ],
            mechanics: PoseMechanics(alignmentPrinciple: "Single-leg balance with foot on inner thigh or calf", commonCorrection: "Don't place foot on knee", keyEngagement: "Standing leg and core"),
            muscleGroup: "Legs, Core, Ankles",
            variations: ["Arms in prayer", "Arms overhead", "Eyes closed"],
            imageURL: "figure.yoga",
            category: .balance,
            difficulty: .beginner
        )
    ]
}
